require 'forwardable'

require 'colorize'
require 'rosh/host'

require_relative 'logger'
require_relative 'host_changes'
require_relative 'actions'
require_relative 'environment'
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
    extend Forwardable

    include Screenplay::Actions
    include LogSwitch::Mixin

    attr_reader :host_changes

    # @param [Rosh::Host] host
    def initialize(host)
      @host = host
      log "Initialized for host: #{@host.hostname}"
      @results = []
      @host_changes = HostChanges.new
      @host.packages.add_observer(@host_changes)
    end

    def_delegators :@host, :hostname, :user, :shell, :operating_system,
      :kernel_version, :architecture, :distribution, :distribution_version,
      :remote_shell, :services, :packages


    def directory(path,
      state: :exists,
      owner: nil,
      group: nil,
      mode: nil,
      on_fail: nil)

      dir = @host.fs.directory(path)
      dir.add_observer(@host_changes)

      case state
      when :absent
        dir.remove if dir.exists?
      when :exists
        dir.create unless dir.exists?

        puts "owner: #{dir.owner}"
        if owner && dir.owner != owner
          dir.owner = owner
        end

        puts "group: #{dir.group}"
        if group && dir.group != group
          dir.group = group
        end

        puts "mode: #{dir.mode}"
        if mode && dir.mode != mode
          dir.mode = mode
        end
      else
        raise "Unknown state: #{state}"
      end

      @results << {
        actor: :directory,
        arguments: { state: state, owner: owner, mode: mode }
      }
    end
=begin
    def action!
      log 'Starting action...'
      puts "Executing action on host '#{@hostname}'".blue

      start_time = Time.now

      Screenplay::Environment.hosts[@hostname].shell.exec_stored do |result|

      end

      puts "Screenplay finished performing\nTotal Duration: #{Time.now - start_time}".green
    end

    def run_action(action)
      #puts "Running #{action.class} command: '#{action.command}'".blue
      result = action.build_result(@hostname)
      raise 'Action result status was nil' if result.status.nil?

      if result.failed?
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
      elsif result.no_change?
        puts "Screenplay finished [NO CHANGE]: '#{action.command}'".yellow
      elsif result.updated?
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
=end
  end
end
