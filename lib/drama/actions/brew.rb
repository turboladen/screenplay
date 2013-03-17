require_relative '../action'


class Drama
  module Actions
    class Brew < Drama::Action
      def initialize(
        formula: formula,
        state: :installed,
        update: false,
        binary: '/usr/local/bin/brew',
        force: false
      )
        action = case state
        when :latest then 'upgrade'
        when :installed then 'install'
        when :removed then 'remove'
        end

        command ''
        command << "#{binary} update && "  if update
        command << "#{binary} #{action} #{formula}"
        command << ' --force'                   if force

        super(command)
      end

      # @return [Hash]
      def act(ssh, host)
        outcome = super(ssh, host)
        return outcome if outcome.exception?

        outcome.status = case outcome.ssh_output.exit_code
        when 0
          :updated
        when 1
          if outcome.ssh_output.stdout.match /already installed/
            :no_change
          else
            :failed
          end
        else
          :failed
        end

        outcome
      end
    end
  end
end
