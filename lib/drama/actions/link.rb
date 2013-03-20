require_relative '../action'


class Drama
  module Actions
    class Link < Drama::Action
      def initialize(
        source: source,
        target: target,
        state: :exists,
        symbolic: true,
        on_fail: nil
      )
        @on_fail = on_fail

        command = case state
        when :absent then "rm -rf #{source}"
        when :exists then file_exists?(source)
        else raise "Unknown state: #{state}"
        end

        super(command)
      end

      def perform(hostname)
        outcome = Drama::Environment.hosts[hostname].ssh.run(@command)
        return outcome if outcome.error?

        outcome.status = case outcome.ssh_output.exit_code
        when 0
          :updated
        else
          handle_on_fail
          :failed
        end

        outcome
      end
    end
  end
end
