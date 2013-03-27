require_relative '../action'


class Screenplay
  module Actions
    class Git < Screenplay::Action
      def initialize(
        repository: repository,
        destination: destination,
        binary: '/usr/bin/env git',
        depth: nil,
        on_fail: nil
      )
        @destination = destination
        @on_fail = on_fail

        command = file_exists?(@destination) + ' && '
        command << "#{binary} pull "
        command << "--depth=#{depth} " if depth
        command << "#{@destination} || "
        command << "#{binary} clone "
        command << "--depth=#{depth} " if depth
        command << "#{repository} #{@destination}"

        super(command)
      end

      def perform(hostname)
        result = Screenplay::Environment.hosts[hostname].ssh.run(@command)
        return result if result.exception?

        result.status = case result.exit_code
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
