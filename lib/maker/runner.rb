require 'etc'
require 'blockenspiel'
require 'colorize'
require 'net/ssh/simple'

Dir[File.dirname(__FILE__) + '/actions/*.rb'].each(&method(:require))

class Maker
  class Runner
    include Blockenspiel::DSL

    def self.run(&block)
      Blockenspiel.invoke(block, new)
    end

    def initialize
      @actions = []

      @config = {
        user: Etc.getlogin,
        ssh_timeout: 120
      }
    end

    def set(**options)
      @config.merge! options
    end

    def method_missing(meth, *args, &block)
      super unless defined? Maker::Actions

      action = Maker::Actions.constants.find { |c| c.to_s.downcase.to_sym == meth }

      if action.nil?
        super
      else
        klass = Maker::Actions.const_get(action)
        @actions << klass.new(ssh, @config[:host], *args, &block)
      end
    end

    def ssh
      return @ssh if @ssh

      @ssh = Net::SSH::Simple.new(ssh_options)
    end

    def ssh_options
      options = {
        user: @config[:user],
        timeout: @config[:ssh_timeout]
        #  verbose: :debug
      }

      options.merge!(keys: @config[:ssh_key_path]) if @config[:ssh_key_path]

      options
    end

    def maker_failure(exception)
      if exception.result.success
        error = <<-ERROR
*** Maker Error! ***
* Exception: #{exception.wrapped}
* Exception class: #{exception.wrapped.class}
* Plan duration: #{exception.result.finish_at - exception.result.start_at || 0}
* SCP source: #{exception.result.opts[:scp_src]}
* SCP destination: #{exception.result.opts[:scp_dst]}
* STDERR: #{exception.result.stderr}
        ERROR

        abort(error.red)
      else
        raise exception
      end
    end

    def plan_failure(output, start_time)
      error = <<-ERROR
*** Maker Plan Failure! ***
* Plan failed: #{output.cmd}
* Exit code: #{output.exit_code}
* Plan Duration: #{output.finish_at - output.start_at}
* Total Duration: #{output.finish_at - start_time}
* STDERR: #{output.stderr}
      ERROR

      abort(error.red)
    end

    def act
      abort('Must use Ruby 2.0.0 or greater with maker.') if RUBY_VERSION < '2.0.0'
      start_time = Time.now
      puts "config: #{@config}"
      puts "ssh options: #{ssh_options}"
      puts "Executing action on host '#{@config[:host]}'".blue

      @actions.each do |cmd|
        puts "Running command: '#{cmd.command}'".blue
        outcome = cmd.run

        p outcome

        if outcome.status == :failed
          plan_failure(outcome.ssh_output, start_time)
        elsif outcome.status == :no_change
          puts "Maker finished [NO CHANGE]: '#{cmd.command}'".yellow
        elsif outcome.status == :updated
          puts "Maker finished [UPDATED]: '#{cmd.command}'".green
        else
          puts "WTF? status: #{outcome.status}"
        end
      end

      puts "Maker finished making\nTotal Duration: #{Time.now - start_time}".green
    end

    def exec_ssh(cmd, start_time)
      puts "executing command: '#{cmd}' as user #{@config[:user]} on #{@config[:host]}".blue

      begin
        r = ssh(@config[:host], cmd, ssh_options)
      rescue Net::SSH::Simple::Error => ex
        maker_failure(ex)
      end

      if r.exit_code.zero?
        puts "Maker finished: '#{r.cmd}'".green
      else
        p r
        plan_failure(r, start_time)
      end
    end

    def get_binding
      binding
    end
  end
end
