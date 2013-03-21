require_relative '../action'


class Screenplay
  module Actions
    class Subversion < Screenplay::Action
      def initialize(
        repository: repository,
        destination: destination,
        binary: '/usr/bin/env svn',
        on_fail: nil
      )
        @destination = destination
        @on_fail = on_fail

        command = file_exists?(@destination) + ' && '
        command << "#{binary} update #{@destination} || "
        command << "#{binary} checkout #{repository} #{@destination}"

        super(command)
      end

      def perform(hostname)
        result = Screenplay::Environment.hosts[hostname].ssh.run(@command)
        return result if result.error?

        result.status = case result.ssh_output.exit_code
        when 0
          if result.ssh_output.stdout.match(/[A-Za-z]\s+#{@destination}/m)
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
