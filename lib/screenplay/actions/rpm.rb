require_relative '../action'


class Screenplay
  module Actions
    # @todo source: lets you point to a URL instead of using on_fail
    class Rpm < Screenplay::Action
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

      def perform(hostname)
        result = Screenplay::Environment.hosts[hostname].ssh.run(@command)
        return result if result.error?

        result.status = case result.ssh_output.exit_code
        when 0
          if result.ssh_output.stdout.match(/#{@package}/m)
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
