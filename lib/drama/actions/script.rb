require_relative '../action'


class Drama
  module Actions
    class Script < Drama::Action
      def initialize(
        source_file: source_file,
        args: nil
      )
        @remote_file = "/tmp/drama.#{Time.now.to_i}"
        @source_file = ::File.expand_path(source_file)

        command = "chmod +x #{@remote_file} && #{@remote_file}"
        command << " #{args}" if args

        super(command)
      end

      def perform(hostname)
        Drama::Environment.hosts[hostname].ssh.upload(@source_file, @remote_file)
        outcome = Drama::Environment.hosts[hostname].ssh.run(@command)
        return outcome if outcome.error?

        outcome.status = case outcome.ssh_output.exit_code
        when 0
          :updated
        else
          :failed
        end

        outcome
      end
    end
  end
end
