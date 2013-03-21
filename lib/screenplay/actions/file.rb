require_relative '../action'
require 'open-uri'


class Screenplay
  module Actions
    class File < Screenplay::Action
      def initialize(
        path: path,
        state: :exists,
        source: nil,
        on_fail: nil
      )
        @path = path
        @source = source
        @on_fail = on_fail

        command = case state
        when :absent then "rm -rf #{@path}"
        when :exists then file_exists?(@path)
        else raise "Unknown state: #{state}"
        end

        super(command)
      end

      def perform(hostname)
        if @source
          source_file = if ::File.exists?(@source)
            @source
          else
            log "Getting remote source file from #{@source}"

            begin
              open(@source)
            rescue OpenURI::HTTPError => ex
              handle_on_fail
              return Screenplay::ActionResult.new(ex, :failed)
            end
          end

          log "Uploading source file #{@source}"
          Screenplay::Environment.hosts[hostname].ssh.upload(source_file, @path)
        end

        result = Screenplay::Environment.hosts[hostname].ssh.run(@command)
        return result if result.error?

        result.status = case result.ssh_output.exit_code
        when 0
          :updated
        else
          handle_on_fail
          :failed
        end

        result
      end
    end
  end
end
