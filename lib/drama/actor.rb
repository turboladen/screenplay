require 'blockenspiel'
require 'etc'
require 'colorize'
require 'net/ssh/simple'
require_relative 'part'
require_relative 'actions'


class Drama

  # An Actor runs Drama::Actions on a remote host.
  #
  # Use block form:
  #   actor = Drama::Actor.act_on 'my_box' do
  #     apt package: 'subversion', state: :installed
  #     subversion repo: 'http://my_repo.googlecode.com/svn/trunk', dest: '/home/me/my_repo'
  #   end
  #
  #   actor.action!
  #
  # Or not:
  #   actor = Drama::Actor.new 'my_box'
  #   actor.apt package: 'subversion', state: :installed
  #   actor.subversion repo: 'http://my_repo.googlecode.com/svn/trunk', dest: '/home/me/my_repo'
  #   actor.action!
  #
  class Actor
    include Blockenspiel::DSL
    include Drama::Actions

    def self.act_on(host=nil, &block)
      actor = new(host)
      Blockenspiel.invoke(block, actor)

      actor
    end

    def initialize(host)
      @actions = []

      @config = {
        user: Etc.getlogin,
        ssh_timeout: 120,
        host: host
      }
    end

    def set(**options)
      @config.merge! options
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

    def drama_failure(exception)
      if exception.result.success
        error = <<-ERROR
*** Drama Error! ***
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
*** Drama Plan Failure! ***
* Plan failed: #{output.cmd}
* Exit code: #{output.exit_code}
* Plan Duration: #{output.finish_at - output.start_at}
* Total Duration: #{output.finish_at - start_time}
* STDERR: #{output.stderr}
      ERROR

      abort(error.red)
    end

    def action!
      abort('Must use Ruby 2.0.0 or greater with drama.') if RUBY_VERSION < '2.0.0'
      start_time = Time.now
      puts "config: #{@config}"
      puts "ssh options: #{ssh_options}"
      puts "Executing action on host '#{@config[:host]}'".blue
      puts "Actions: #{@actions}"

      @actions.each do |cmd|
        puts "Running command: '#{cmd.command}'".blue
        outcome = cmd.act(ssh, @config[:host])
        puts "outcome: #{outcome}"

        if outcome.status == :failed
          plan_failure(outcome.ssh_output, start_time)
        elsif outcome.status == :no_change
          puts "Drama finished [NO CHANGE]: '#{cmd.command}'".yellow
        elsif outcome.status == :updated
          puts "Drama finished [UPDATED]: '#{cmd.command}'".green
        else
          puts "WTF? status: #{outcome.status}"
        end

      end

      puts "Drama finished performing\nTotal Duration: #{Time.now - start_time}".green
    end

    def play_part(part_class, **options)
      part_class.act(self, **options)
    end

    def get_binding
      binding
    end
  end
end
