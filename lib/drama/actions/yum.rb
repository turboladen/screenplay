require_relative '../action'


class Drama
  module Actions
    class Yum < Drama::Action
      def initialize(
        package: nil,
        state: :installed,
        update_cache: false,
        upgrade: false,
        sudo: false,
        on_fail: nil
      )
        @package = package
        @on_fail = on_fail

        action = case state
        when :latest then 'install'
          # install should just check to see if it's installed, not always install it
        when :installed then 'install'
        when :removed then 'remove'
        end

        commands = []
        commands << 'yum upgrade -y'              if upgrade
        commands << 'yum update -y'               if update_cache
        commands << "yum #{action} -y #{package}" if package
        commands.map! { |c| "sudo #{c}" }         if sudo

        command = commands.size == 1 ? commands.first : commands.join(' && ')

        super(command)
      end

      def perform(hostname)
        outcome = Drama::Environment.hosts[hostname].ssh.run(@command)
        return outcome if outcome.error?

        outcome.status = case outcome.ssh_output.exit_code
        when 0
          stdout = outcome.ssh_output.stdout
          if stdout.match(/Installed:\s+#{@package}/)
            :updated
          else
            :no_change
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
