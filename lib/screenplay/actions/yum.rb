require_relative '../action'


class Screenplay
  module Actions
    # @todo source: lets you point to a URL instead of using on_fail
    class Yum < Screenplay::Action
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
        result = Screenplay::Environment.hosts[hostname].ssh.run(@command)
        return result if result.exception?

        result.status = case result.exit_code
        when 0
          stdout = result.stdout
          if stdout.match(/Installed:\s+#{@package}/)
            :updated
          else
            :no_change
          end
        else
          handle_on_fail
          :failed
        end

        result
      end
    end
  end
end
