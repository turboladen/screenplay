require_relative '../action'


class Drama
  module Actions
    class Subversion < Drama::Action
      def initialize(
        repository: repository,
        destination: destination,
        binary: '/usr/bin/env svn'
      )
        @destination = destination

        command = file_exists?(@destination) + ' && '
        command << "#{binary} update #{@destination} || "
        command << "#{binary} checkout #{repository} #{@destination}"

        super(command)
      end

      def act(ssh, host)
        outcome = run_command(ssh, host)
        return outcome if outcome.error?

        outcome.status = case outcome.ssh_output.exit_code
        when 0
          if outcome.ssh_output.stdout.match /[A-Za-z]\s+#{@destination}/m
            :updated
          else
            :no_change
          end
        else
          :failed
        end

        outcome
      end
    end
  end
end
