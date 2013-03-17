require_relative '../action'


class Drama
  module Actions
    class Apt < Drama::Action
      def initialize(
        package: package,
        state: :installed,
        update_cache: false,
        sudo: false
      )
        super()

        action = case state
        when :latest then 'install'
          # install should just check to see if it's installed, not always install it
        when :installed then 'install'
        when :removed then 'remove'
        end

        if update_cache
          @command << 'sudo '              if sudo
          @command << 'apt-get update && '
        end

        @command << 'sudo '              if sudo
        @command << "apt-get #{action} #{package}"
      end

      def call(ssh, host)
        outcome = super(ssh, host)
        return outcome if outcome.exception?

        outcome.status = case outcome.ssh_output.exit_code
        when 0
          if outcome.ssh_output.stdout.match /is already the newest version/m
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
