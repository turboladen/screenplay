require_relative '../action'


class Drama
  module Actions
    class Directory < Drama::Action
      def initialize(
        path: path,
        state: :exists,
        owner: nil,
        mode: nil
      )
        command = case state
        when :absent
          "rm -rf #{path} "
        when :exists
          cmd = "#{file_exists?(path)} || mkdir -p #{path}"
          cmd << %[ && chown #{owner} #{path} ] if owner
          cmd << %[ && chmod #{mode} #{path} ] if mode
          cmd
        else
          raise "Unknown state: #{state}"
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
          if outcome.ssh_output.stdout.match /File exists/
            :no_change
          else
            :failed
          end
        end

        outcome
      end
    end
  end
end
