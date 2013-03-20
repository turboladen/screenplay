require_relative '../action'
require_relative '../environment'


class Screenplay
  module Actions
    class Apt < Screenplay::Action
      def initialize(
        package: package,
        state: :installed,
        update_cache: false,
        sudo: false,
        on_fail: nil
      )
        @on_fail = on_fail

        action = case state
        when :latest then 'install'
          # install should just check to see if it's installed, not always install it
        when :installed then 'install'
        when :removed then 'remove'
        end

        command = ''

        if update_cache
          command << 'sudo '            if sudo
          command << 'apt-get update && '
        end

        command << 'sudo '              if sudo
        command << "apt-get #{action} #{package}"

        super(command)
      end

      def perform(hostname)
        outcome = Screenplay::Environment.hosts[hostname].ssh.run(@command)
        return outcome if outcome.error?

        outcome.status = case outcome.ssh_output.exit_code
        when 0
          if outcome.ssh_output.stdout.match /is already the newest version/m
            :no_change
          else
            :updated
          end
        else
          handle_on_fail
          :failed
        end

        outcome
      end
    end
  end
end
