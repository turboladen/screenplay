require_relative '../action'


class Drama
  module Actions
    class Yum < Drama::Action
      def initialize(
        package: package,
          state: :installed,
          update_cache: false,
          sudo: false
      )
        action = case state
        when :latest then 'install'
          # install should just check to see if it's installed, not always install it
        when :installed then 'install'
        when :removed then 'remove'
        end

        command = ''

        if update_cache
          command << 'sudo '              if sudo
          command << 'yum update && '
        end

        command << 'sudo '              if sudo
        command << "yum #{action} -y #{package}"

        super(command)
      end

      def act(ssh, host)
        outcome = run_command(ssh, host)
        return outcome if outcome.error?

        outcome.status = case outcome.ssh_output.exit_code
        when 0
          if outcome.ssh_output.stdout.match /already installed and latest version\nNothing to do/m
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
