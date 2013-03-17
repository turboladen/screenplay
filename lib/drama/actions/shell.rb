require_relative '../action'


class Drama
  module Actions
    class Shell < Drama::Action
      def initialize(command: cmd)
        super()
        @command = command
      end

      def call(ssh, host)
        outcome = super(ssh, host)
        return outcome if outcome.exception?

        outcome.status = case outcome.ssh_output.exit_code
        when 0
          :updated
        else
          :failed
        end

        outcome
      end
    end
  end
end
