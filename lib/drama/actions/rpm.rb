require_relative '../action'


class Drama
  module Actions
    class Rpm < Drama::Action
      def initialize(
        package: package,
        state: :installed,
        sudo: false,
        on_fail: nil
      )
        @on_fail = on_fail

        action = case state
        when :latest then '-Uvh'
        when :installed then '-ivh'
        when :removed then '-evh'
        end

        commands = []
        commands << "rpm -q #{package} || "
        commands << "rpm #{action} #{package}"

        if sudo
          commands.map! { |command| "sudo #{command}" }
        end

        super(commands.join(' '))
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
          if outcome.ssh_output.stdout.match(/is not installed/) && @on_fail
            puts 'Command failed; setting up to run failure block...'.yellow
            @fail_block = @on_fail
          end

          :failed
        end

        outcome
      end
    end
  end
end
