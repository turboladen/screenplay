require_relative 'outcome'


class Maker
  class Action
    attr_reader :command

    def initialize(ssh, host)
      @ssh = ssh
      @host = host
      @command = ''
    end

    # @return [Maker::Outcome]
    def run
      begin
        output = @ssh.ssh(@host, @command)
        Maker::Outcome.new(output)
      rescue Net::SSH::Simple::Error => ex
        Maker::Outcome.new(ex, :failed)
      end
    end

    def file_exists?(path)
      "[ -f #{path} ]"
    end
  end
end
