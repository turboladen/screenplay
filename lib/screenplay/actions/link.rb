require_relative '../action'


class Screenplay
  module Actions
    class Link < Screenplay::Action
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
        result = Screenplay::Environment.hosts[hostname].ssh.run(@command)
        return result if result.error?

        result.status = case result.ssh_output.exit_code
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
