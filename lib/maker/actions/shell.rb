require_relative '../action'


class Maker
  module Actions
    class Shell < Maker::Action
      def initialize(ssh, host,
        cmd
      )
        super(ssh, host)
        @command = cmd
      end

      def run
        outcome = super
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