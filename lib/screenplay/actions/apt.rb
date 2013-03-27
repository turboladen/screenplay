require_relative '../action'
require_relative '../environment'


class Screenplay
  module Actions
    # @todo source: lets you point to a URL instead of using on_fail
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
        result = Screenplay::Environment.hosts[hostname].ssh.run(@command)
        return result if result.exception?

        result.status = case result.exit_code
        when 0
          if result.stdout.match(/is already the newest version/m)
            :no_change
          else
            :updated
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
