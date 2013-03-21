require_relative '../action'


class Screenplay
  module Actions
    class Brew < Screenplay::Action
      def initialize(
        formula: formula,
        state: :installed,
        update: false,
        binary: '/usr/local/bin/brew',
        force: false,
        on_fail: nil
      )
        @on_fail = on_fail

        action = case state
        when :latest then 'upgrade'
        when :installed then 'install'
        when :removed then 'remove'
        end

        command = ''
        command << "#{binary} update && "  if update
        command << "#{binary} #{action} #{formula}"
        command << ' --force'                   if force

        super(command)
      end

      # @return [Hash]
      def perform(hostname)
        result = Screenplay::Environment.hosts[hostname].ssh.run(@command)
        return result if result.error?

        result.status = case result.ssh_output.exit_code
        when 0
          :updated
        when 1
          if result.ssh_output.stdout.match(/already installed/)
            :no_change
          else
            :failed
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
