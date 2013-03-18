require_relative '../action'


class Drama
  module Actions
    class Rpm < Drama::Action
      def initialize(
        package: package,
        state: :installed,
        sudo: false
      )
        action = case state
        when :latest then '-Uvh'
        when :installed then '-Uvh'
        when :removed then '-e'
        end

        command = ''
        command << 'sudo ' if sudo
        command << "rpm #{action} #{package}"

        super(command)
      end

      def act(ssh, host)
        outcome = run_command(ssh, host)
        return outcome if outcome.error?

        outcome.status = case outcome.ssh_output.exit_code
        when 0
          if outcome.ssh_output.stdout.match /already installed and version/m
            :no_change
          else
            :updated
          end
        else
          :failed
        end

        outcome
      end
    end
  end
end
