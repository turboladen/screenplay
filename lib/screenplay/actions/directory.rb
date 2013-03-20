require_relative '../action'


class Screenplay
  module Actions
    class Directory < Screenplay::Action
      def initialize(
        path: path,
        state: :exists,
        owner: nil,
        mode: nil,
        sudo: false,
        on_fail: nil
      )
        @on_fail = on_fail

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

      def perform(hostname)
        outcome = Screenplay::Environment.hosts[hostname].ssh.run(@command)
        return outcome if outcome.error?

        outcome.status = case outcome.ssh_output.exit_code
        when 0
          :updated
        else
          if outcome.ssh_output.stdout.match(/File exists/)
            :no_change
          else
            handle_on_fail
            :failed
          end
        end

        outcome
      end
    end
  end
end