require_relative '../action'


class Drama
  module Actions
    class Script < Drama::Action
      def initialize(
        source_file: source_file,
        args: nil
      )
        super()

        @remote_file = "/tmp/drama.#{Time.now.to_i}"
        @source_file = ::File.expand_path(source_file)

        @command << "chmod +x #{@remote_file} && #{@remote_file}"
        @command << " #{args}" if args
      end

      def act(ssh, host)
        uploader = proc { ssh.scp_ul(host, @source_file, @remote_file) }
        uploader.call

        outcome = super
        return outcome if outcome.exception?

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
