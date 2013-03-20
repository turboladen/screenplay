require_relative '../action'


class Screenplay
  module Actions
    class Script < Screenplay::Action
      def initialize(
        source_file: source_file,
        args: nil,
        on_fail: nil
      )
        @remote_file = "/tmp/screenplay.#{Time.now.to_i}"
        @source_file = ::File.expand_path(source_file)

        command = "chmod +x #{@remote_file} && #{@remote_file}"
        command << " #{args}" if args

        super(command)
      end

      def perform(hostname)
        Screenplay::Environment.hosts[hostname].ssh.upload(@source_file, @remote_file)
        outcome = Screenplay::Environment.hosts[hostname].ssh.run(@command)
        return outcome if outcome.error?

        outcome.status = case outcome.ssh_output.exit_code
        when 0
          :updated
        else
          handle_on_fail
          :failed
        end

        outcome
      end
    end
  end
end
