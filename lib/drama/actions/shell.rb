require_relative '../action'


class Drama
  module Actions
    class Shell < Drama::Action
      def initialize(command: command)
        super(command)
      end

      def act(ssh, host)
        outcome = run_comman(ssh, host)
        return outcome if outcome.error?

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
