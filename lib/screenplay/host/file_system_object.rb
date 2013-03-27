require 'tempfile'


class Screenplay
  class Host
    class FileSystemObject
      attr_reader :path

      def initialize(path, ssh, &result_block)
        @path = path
        @ssh = ssh
        @result_block = result_block
      end

      def file?
        cmd = "[ -f #{@path} ]"
        result = @ssh.run(cmd)
        @result_block.call(result)

        result.exit_code.zero?
      end

      def directory?
        cmd = "[ -d #{@path} ]"
        result = @ssh.run(cmd)
        @result_block.call(result)

        result.exit_code.zero?
      end

      def link?
        cmd = "[ -L #{@path} ]"
        result = @ssh.run(cmd)
        @result_block.call(result)

        result.exit_code.zero?
      end

      def exists?
        cmd = "[ -e #{@path} ]"
        result = @ssh.run(cmd)
        @result_block.call(result)

        result.exit_code.zero?
      end

      def read
        cmd = "cat #{@path}"
        result = @ssh.run(cmd)
        @result_block.call(result)

        result.exit_code.zero?

        result.stdout
      end

      def write(new_content)
        source_file = Tempfile.new('screenplay_fso')
        source_file.write(new_content)
        source_file.rewind

        result = @ssh.upload(source_file.path, @path)

        @result_block.call(result)
        result.stderr.empty?
      ensure
        source_file.close
        source_file.unlink
      end

    end
  end
end
