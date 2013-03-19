require 'colorize'
require_relative 'logger'
require_relative 'ssh'
require_relative 'actions'
require_relative 'environment'
require_relative 'host_environment'
require_relative 'part'


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

    attr_reader :hostname
    attr_reader :name

    def initialize(hostname, name='', **ssh_options)
      @hostname = hostname
      @name = name
      @actions = []
      @ssh_options = ssh_options

      log "Initialized for host: #{@hostname}"
      Drama::Environment.hosts[hostname] = self
    end

    def ssh
      @ssh ||= Drama::SSH.new(@hostname, @ssh_options)
    end

    def env
      @env ||= Drama::HostEnvironment.new(ssh, @hostname)
    end

    def action!
      log 'Starting action...'
      log "...hostname: #{@hostname}"
      log "...ssh options: #{@ssh_options}"
      log "...actions: #{@actions}"
      puts "Executing action on host '#{@hostname}'".blue

      start_time = Time.now

      @actions.each do |cmd|
        run_action(cmd)
      end

      puts "Drama finished performing\nTotal Duration: #{Time.now - start_time}".green
    end

    def run_action(action)
      puts "Running command: '#{action.command}'".blue
      outcome = action.perform(@hostname)
      raise 'Outcome status was nil' if outcome[:status].nil?

      if outcome.status == :failed
        if action.fail_block
          actions_before = @actions.size
          action.fail_block.call
          new_action_count = @actions.size - actions_before
          puts "new actikon count: #{new_action_count}".light_green
          new_actions = @actions.pop(new_action_count)

          new_actions.each do |command|
            run_action(command)
          end
        else
          plan_failure(outcome.ssh_output)
        end
      elsif outcome.status == :no_change
        puts "Drama finished [NO CHANGE]: '#{action.command}'".yellow
      elsif outcome.status == :updated
        puts "Drama finished [UPDATED]: '#{action.command}'".green
      else
        puts "WTF? status: #{outcome.status}".red
      end
    end

    def play_part(part_class, **options)
      part_class.play(self, **options)
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

    def plan_failure(output)
      log "Plan Failure: #{output}"

      error = <<-ERROR
*** Drama Plan Failure! ***
* Plan failed: #{output.cmd}
* Exit code: #{output.exit_code}
* Plan Duration: #{output.finish_at - output.start_at}
* STDERR: #{output.stderr}
      ERROR

      abort(error.red)
    end
  end
end
