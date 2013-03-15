require_relative 'outcome'


class Drama
  class Action
    attr_reader :command

    def initialize(ssh, host)
      @ssh = ssh
      @host = host
      @command = ''
    end

    # @return [Drama::Outcome]
    def run
      begin
        output = @ssh.ssh(@host, @command)
        Drama::Outcome.new(output)
      rescue Net::SSH::Simple::Error => ex
        Drama::Outcome.new(ex, :failed)
      end
    end

    def file_exists?(path)
      "[ -f #{path} ]"
    end
  end
end
