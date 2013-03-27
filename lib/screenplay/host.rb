require 'colorize'
require_relative 'logger'
require_relative 'ssh'
require_relative 'actions'
require_relative 'environment'
require_relative 'host/environment'
require_relative 'host/file_system'
require_relative 'part'


class Screenplay

  # An Host runs Screenplay::Actions on a remote host.
  #
  #   host = Screenplay::Host.new 'my_box'
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
    include Screenplay::Actions
    include LogSwitch::Mixin

    attr_reader :hostname
    attr_reader :name

    def initialize(hostname, name='', **ssh_options)
      @hostname = hostname
      @name = name
      @actions = []
      @ssh_options = ssh_options

      log "Initialized for host: #{@hostname}"
      Screenplay::Environment.hosts[hostname] = self
    end

    def ssh
      @ssh ||= Screenplay::SSH.new(@hostname, @ssh_options)
    end

    def env
      @env ||= Screenplay::Host::Environment.new(@hostname)
    end

    def fs
      @fs ||= Screenplay::Host::FileSystem.new(@hostname)
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

      puts "Screenplay finished performing\nTotal Duration: #{Time.now - start_time}".green
    end

    def run_action(action)
      puts "Running #{action.class} command: '#{action.command}'".blue
      result = action.perform(@hostname)
      raise 'Action result status was nil' if result.status.nil?

      if result.status == :failed
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
          plan_failure(result)
        end
      elsif result.status == :no_change
        puts "Screenplay finished [NO CHANGE]: '#{action.command}'".yellow
      elsif result.status == :updated
        puts "Screenplay finished [UPDATED]: '#{action.command}'".green
      else
        puts "WTF? status: #{result.status}".red
        puts "WTF? status class: #{result.status.class}".red
      end
    end

    def play_part(part_class, **options)
      part_class.play(self, **options)
    end

    def drama_failure(result)
      log "Screenplay Failure: #{result}"

      if result.success
        error = <<-ERROR
*** Screenplay Error! ***
* Exception: #{result.exception}
* Exception class: #{result.exception.class}
* Plan duration: #{result.finished_at - result.started_at || 0}
* SCP source: #{result.ssh_options[:scp_src]}
* SCP destination: #{result.ssh_options[:scp_dst]}
* STDERR: #{result.stderr}
        ERROR

        abort(error.red)
      else
        raise result.exception
      end
    end

    def plan_failure(result)
      log "Plan Failure: #{result}"

      error = <<-ERROR
*** Screenplay Plan Failure! ***
* Plan failed: #{result.command}
* Exit code: #{result.exit_code}
* Plan Duration: #{result.finished_at - result.started_at}
* STDERR: #{result.stderr}
      ERROR

      abort(error.red)
    end
  end
end
