require_relative 'logger'
require_relative 'outcome'


class Drama
  class Action
    include LogSwitch::Mixin

    attr_reader :command

    def initialize(command)
      @command = command

      log "command: #{@command}"
    end

    # @return [Drama::Outcome]
    def act(ssh, host)
      outcome = begin
        output = ssh.ssh(host, @command)
        Drama::Outcome.new(output)
      rescue Net::SSH::Simple::Error => ex
        Drama::Outcome.new(ex, :failed)
      end

      log "Outcome: #{outcome}"
      outcome
    end

    def file_exists?(path)
      "[ -f #{path} ]"
    end

    def user_exists?(username)
      "id -u #{username} >/dev/null 2>&1"
    end
  end
end
