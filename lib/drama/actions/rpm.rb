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
        @package = package

        action = case state
        when :latest then '-Uvh'
        when :installed then '-Uvh'
        when :removed then '-e'
        end

        commands = []
        commands << "rpm -qa | grep #{@package} || "
        commands << "rpm #{action} #{@package}"
        commands.map! { |command| "sudo #{command}" } if sudo

        super(commands.join(' '))
      end

      def act(ssh, host)
        outcome = run_command(ssh, host)
        return outcome if outcome.error?

        outcome.status = case outcome.ssh_output.exit_code
        when 0
          if outcome.ssh_output.stdout.match /#{@package}/m
            :no_change
          else
            :updated
          end
        else
          if @on_fail
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
