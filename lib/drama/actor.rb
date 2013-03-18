require 'blockenspiel'
require 'etc'
require 'colorize'
require 'net/ssh/simple'
require_relative 'part'
require_relative 'actions'
require_relative 'logger'


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
    include LogSwitch::Mixin

    def self.act_on(host, &block)
      actor = new(host)
      Blockenspiel.invoke(block, actor)

      actor
    end

    attr_reader :config

    def initialize(host)
      @actions = []

      @config = {
        user: Etc.getlogin,
        ssh_timeout: 120,
        host: host
      }
      log "Initialized for host: #{host}"
    end

    def set(**options)
      log "Adding options: #{options}"
      @config.merge! options
    end

    def ssh
      return @ssh if @ssh

      @ssh = Net::SSH::Simple.new(ssh_options)
    end

    def ssh_options
      @ssh_options ||= {
        user: @config[:user],
        timeout: @config[:ssh_timeout]
        #  verbose: :debug
      }

      @ssh_options.merge!(keys: @config[:ssh_key_path]) if @config[:ssh_key_path]

      @ssh_options
    end

    def action!
      log 'Starting action...'
      log "...config: #{@config}"
      log "...ssh options: #{ssh_options}"
      log "...actions: #{@actions}"
      puts "Executing action on host '#{@config[:host]}'".blue

      start_time = Time.now

      @actions.each do |cmd|
        puts "Running command: '#{cmd.command}'".blue
        outcome = cmd.act(ssh, @config[:host])
        raise 'Outcome status was nil' if outcome[:status].nil?

        if outcome.status == :failed
          plan_failure(outcome.ssh_output, start_time)
        elsif outcome.status == :no_change
          puts "Drama finished [NO CHANGE]: '#{cmd.command}'".yellow
        elsif outcome.status == :updated
          puts "Drama finished [UPDATED]: '#{cmd.command}'".green
        else
          puts "WTF? status: #{outcome.status}".red
        end

      end

      puts "Drama finished performing\nTotal Duration: #{Time.now - start_time}".green
    end

    def play_part(part_class, **options)
      part_class.act(self, **options)
    end

    def drama_failure(exception)
      log "Drama Failure: #{exception}"

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
      log "Plan Failure: #{exception}"

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

    def get_binding
      binding
    end
  end
end
