require_relative '../action'


class Drama
  module Actions
    class Git < Drama::Action
      def initialize(
        repository: repository,
        destination: destination,
        binary: '/usr/bin/env git',
        depth: nil
      )
        @destination = destination

        command = file_exists?(@destination) + ' && '
        command << "#{binary} pull "
        command << "--depth=#{depth} " if depth
        command << "#{@destination} || "
        command << "#{binary} clone "
        command << "--depth=#{depth} " if depth
        command << "#{@destination}"

        super(command)
      end

      def act(ssh, host)
        outcome = super(ssh, host)
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
