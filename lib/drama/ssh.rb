require 'etc'
require 'net/ssh/simple'
require_relative 'logger'
require_relative 'outcome'


class Drama
  class SSH
    include LogSwitch::Mixin

    attr_reader :options

    DEFAULT_USER = Etc.getlogin
    DEFAULT_TIMEOUT = 1800

    def initialize(hostname, **options)
      @hostname = hostname
      @options = options

      @options[:user] = DEFAULT_USER unless @options.has_key? :user
      @options[:timeout] = DEFAULT_TIMEOUT unless @options.has_key? :ssh_timeout
      @ssh = Net::SSH::Simple.new(@options)
    end

    def set(**options)
      log "Adding options: #{options}"
      @options.merge! options
    end

    def run(command, **ssh_options)
      outcome = begin
        output = @ssh.ssh(@hostname, command, ssh_options) do |event, channel, data|
          case event
          when :stdout
            (@buffer ||= '') << data
            while line = @buffer.slice!(/(.*)\r?\n/)
              print line.light_blue
            end
          when :stderr
            (@buffer ||= '') << data
            while line = @buffer.slice!(/(.*)\r?\n/)
              print line.light_red
            end
          when :finish
            puts 'Finished executing command.'.light_blue
          end
        end
        Drama::Outcome.new(output)
      rescue Net::SSH::Simple::Error => ex
        log "Net::SSH::Simple::Error raised.  Using options: #{@options}"
        Drama::Outcome.new(ex, :failed)
      end

      log "Outcome: #{outcome}"
      outcome
    end

    def upload(source, destination)
      @ssh.scp_ul(@hostname, source, destination)
    end
  end
end
