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
        outcome = Screenplay::Environment.hosts[hostname].ssh.run(@command)
        return outcome if outcome.error?

        outcome.status = case outcome.ssh_output.exit_code
        when 0
          if outcome.ssh_output.stdout.match /[A-Za-z]\s+#{@destination}/m
            :updated
          else
            :no_change
          end
        else
          handle_on_fail
          :failed
        end

        outcome
      end
    end
  end
end
