require_relative '../action'


class Drama
  module Actions
    class Directory < Drama::Action
      def initialize(
        path: path,
        state: :exists,
        owner: nil,
        mode: nil,
        sudo: false
      )
        command = case state
        when :absent
          cmd = "rm -rf #{path} "
          cmd = "sudo #{cmd}" if sudo
          cmd
        when :exists
          cmd = ''
          cmd << 'sudo ' if sudo
          cmd = "#{file_exists?(path)} || "
          cmd << 'sudo ' if sudo
          cmd << "mkdir -p #{path}"

          if owner
            cmd << ' && '
            cmd << 'sudo ' if sudo
            cmd << %[chown #{owner} #{path} ]
          end

          if mode
            cmd << ' && '
            cmd << 'sudo ' if sudo
            cmd << %[chmod #{mode} #{path} ]
          end

          cmd
        else
          raise "Unknown state: #{state}"
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
