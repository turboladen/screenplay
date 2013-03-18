require_relative '../action'


class Drama
  module Actions
    class File < Drama::Action
      def initialize(
        path: path,
        state: :exists
      )
        command = case state
        when :absent then "rm -rf #{path}"
        when :exists then file_exists?(path)
        else raise "Unknown state: #{state}"
        end

        super(command)
      end

      def act(ssh, host)
        outcome = super(ssh, host)
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
