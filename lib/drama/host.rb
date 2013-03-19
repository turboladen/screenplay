require 'etc'
require 'colorize'
require 'net/ssh/simple'
require_relative 'actions'
require_relative 'part'
require_relative 'logger'


class Drama

  # An Host runs Drama::Actions on a remote host.
  #
  #   host = Drama::Host.new 'my_box'
  #
  #   host.brew formula: 'rbenv'
  #   host.subversion repository: 'http://entmenu.googlecode.com/svn/trunk/',
  #     destination: '/tmp/entmenu'
  #   host.directory path: '/tmp/entmenu', state: :absent
  #   host.shell command: %[/usr/bin/env python -V]
  #   host.directory path: '/tmp/steve'
  #   host.directory path: '/tmp/steve', state: :absent
  #   host.script source_file: 'script_test.rb', args: '--first-arg'
  #
  #   host.action!
  #
  class Host
    include Drama::Actions
    include LogSwitch::Mixin

    attr_reader :config
    attr_reader :name

    def initialize(hostname, name='', config_options={})
      @name = name
      @actions = []

      @config = {
        user: Etc.getlogin,
        ssh_timeout: 1800,
        host: hostname
      }
      @config.merge! config_options

      log "Initialized for host: #{hostname}"
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


      @actions.each do |cmd|
        run_action(cmd)
      end

      puts "Drama finished performing\nTotal Duration: #{Time.now - start_time}".green
    end

    def run_action(cmd)
      start_time = Time.now

      puts "Running command: '#{cmd.command}'".blue
      outcome = cmd.act(ssh, @config[:host])
      raise 'Outcome status was nil' if outcome[:status].nil?

      if outcome.status == :failed
        if cmd.fail_block
          actions_before = @actions.size
          cmd.fail_block.call
          new_action_count = @actions.size - actions_before
          puts "new actikon count: #{new_action_count}".light_green
          new_actions = @actions.pop(new_action_count)

          new_actions.each do |command|
            run_action(command)
          end
        else
          plan_failure(outcome.ssh_output, start_time)
        end
      elsif outcome.status == :no_change
        puts "Drama finished [NO CHANGE]: '#{cmd.command}'".yellow
      elsif outcome.status == :updated
        puts "Drama finished [UPDATED]: '#{cmd.command}'".green
      else
        puts "WTF? status: #{outcome.status}".red
      end
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
      log "Plan Failure: #{output}"

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
