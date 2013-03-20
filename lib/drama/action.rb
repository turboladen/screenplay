require 'colorize'
require_relative 'logger'


class Drama
  class Action
    include LogSwitch::Mixin

    attr_reader :command
    attr_reader :fail_block

    def initialize(command)
      @command = command
      @fail_block = nil
      @on_fail ||= nil

      log "command: #{@command}"
    end

    def file_exists?(path)
      "[ -f #{path} ]"
    end

    def user_exists?(username)
      "id -u #{username} >/dev/null 2>&1"
    end

    def handle_on_fail
      if @on_fail
        puts 'Command failed; setting up to run failure block...'.yellow
        @fail_block = @on_fail
      end
    end
  end
end
