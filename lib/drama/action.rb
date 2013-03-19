require 'colorize'
require_relative 'logger'
require_relative 'outcome'


class Drama
  class Action
    include LogSwitch::Mixin

    attr_reader :command
    attr_reader :fail_block

    def initialize(command)
      @command = command
      @fail_block = nil

      log "command: #{@command}"
    end

    # @return [Drama::Outcome]
    def run_command(ssh, host)
      outcome = begin
        output = ssh.ssh(host, @command) do |event, channel, data|
          case event
          when :stdout
            (@buffer ||= '') << data
            while line = @buffer.slice!(/(.*)\r?\n/)
              print line.light_blue
            end
          when :stderr
            (@buffer ||= '') << data
            while line = @buffer.slice!(/(.*)\r?\n/)
              print line.light_red
            end
          when :finish
            puts 'Finished executing command.'.light_blue
          end
        end
        Drama::Outcome.new(output)
      rescue Net::SSH::Simple::Error => ex
        Drama::Outcome.new(ex, :failed)
      end

      log "Outcome: #{outcome}"
      outcome
    end

    def file_exists?(path)
      "[ -f #{path} ]"
    end

    def user_exists?(username)
      "id -u #{username} >/dev/null 2>&1"
    end
  end
end
