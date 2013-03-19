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

      log "command: #{@command}"
    end

    def file_exists?(path)
      "[ -f #{path} ]"
    end

    def user_exists?(username)
      "id -u #{username} >/dev/null 2>&1"
    end
  end
end
