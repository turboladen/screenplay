require_relative '../action'


class Drama
  module Actions
    class File < Drama::Action
      def initialize(ssh, host,
        path: path,
        state: :exists
      )
        super(ssh, host)

        @command = case state
        when :absent then "rm -rf #{path}"
        when :directory then "mkdir -p #{path}"
        when :exists then file_exists?(path)
        else raise "Unknown state: #{state}"
        end
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
