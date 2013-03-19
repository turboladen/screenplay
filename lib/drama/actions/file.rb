require_relative '../action'
require 'open-uri'


class Drama
  module Actions
    class File < Drama::Action
      def initialize(
        path: path,
        state: :exists,
        source: nil
      )
        @path = path
        @source = source

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
            log "Getting remote source file from #{@source}"

            begin
              open(@source)
            rescue OpenURI::HTTPError => ex
              return Drama::Outcome.new(ex, :failed)
            end
          end

          log "Uploading source file #{@source}"
          ssh.scp_ul(host, source_file, @path)
        end

        outcome = run_command(ssh, host)
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
