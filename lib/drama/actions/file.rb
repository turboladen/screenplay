require_relative '../action'
require 'open-uri'
require 'tempfile'


class Drama
  module Actions
    class File < Drama::Action
      def initialize(
        path: path,
        state: :exists,
        source: nil
      )
        @source = source
        @path = path

        command = case state
        when :absent then "rm -rf #{@path}"
        when :exists then file_exists?(@path)
        else raise "Unknown state: #{state}"
        end

        super(command)
      end

      def act(ssh, host)
        if @source
          source_file = if ::File.exists?(@source)
            @source
          else
            f = Tempfile.new('drama')
            f.write(open(@source).read)
            f
          end

          log ""
          ssh.scp_ul(host, source_file, @path)
        end

        outcome = super(ssh, host)
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
