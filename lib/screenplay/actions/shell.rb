require_relative '../action'


class Screenplay
  module Actions
    class Shell < Screenplay::Action
      def initialize(command: command, sudo: false, on_fail: nil)
        @on_fail = on_fail
        command = "sudo #{command}" if sudo

        super(command)
      end

      def perform(hostname)
        result = Screenplay::Environment.hosts[hostname].ssh.run(@command)
        return result if result.exception?

        result.status = case result.exit_code
        when 0
          :updated
        else
          handle_on_fail
          :failed
        end

        result
      end
    end
  end
end
