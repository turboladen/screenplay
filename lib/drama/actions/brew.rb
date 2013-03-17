require_relative '../action'


class Drama
  module Actions
    class Brew < Drama::Action
      def initialize(
        formula: formula,
        state: :installed,
        update: false,
        prefix: '/usr/local/bin/brew',
        force: false
      )
        super()
        action = case state
        when :latest then 'upgrade'
        when :installed then 'install'
        when :removed then 'remove'
        end

        @command << "#{prefix} update && "  if update
        @command << "#{prefix} #{action} #{formula}"
        @command << ' --force'                   if force
      end

      # @return [Hash]
      def call(ssh, host)
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
