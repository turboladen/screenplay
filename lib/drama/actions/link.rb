require_relative '../action'


class Drama
  module Actions
    class Link < Drama::Action
      def initialize(
        source: source,
        target: target,
        state: :exists,
        symbolic: true
      )
        command = case state
        when :absent then "rm -rf #{source}"
        when :exists then file_exists?(source)
        else raise "Unknown state: #{state}"
        end

        super(command)
      end

      def act(ssh, host)
        outcome = run_command(ssh, host)
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
