require 'etc'
require 'net/ssh/simple'
require_relative 'logger'
require_relative 'outcome'


class Screenplay

  # Wrapper for Net::SSH::Simple to allow for a) not having to pass in the
  # hostname with every SSH call, and b) handle STDOUT and STDERR the same way
  # across SSH commands.
  #
  # Any options passed in to #initialize or set using #set will be used with
  # subsequent #run or #upload commands.
  class SSH
    include LogSwitch::Mixin

    DEFAULT_USER = Etc.getlogin
    DEFAULT_TIMEOUT = 1800

    # @return [Hash] The Net::SSH::Simple options that were during initialization
    #   and via #set.
    attr_reader :options

    # @param [String] hostname Name or IP of the host to SSH in to.
    # @param [Hash] options Net::SSH::Simple options.
    def initialize(hostname, **options)
      @hostname = hostname
      @options = options

      @options[:user] = DEFAULT_USER unless @options.has_key? :user
      @options[:timeout] = DEFAULT_TIMEOUT unless @options.has_key? :timeout
      @ssh = Net::SSH::Simple.new(@options)
    end

    # Easy way to set an SSH option.
    #
    # @param [Hash] options Net::SSH::Simple options.
    def set(**options)
      log "Adding options: #{options}"
      @options.merge! options
    end

    # Runs +command+ on the host for which this SSH object is connected to.
    #
    # @param [String] command The command to run on the remote box.
    # @param [Hash] ssh_options Net::SSH::Simple options.  These will get merged
    #   with options set in #initialize and via #set.  Can be used to override
    #   those settings as well.
    # @return [Screenplay::Outcome]
    def run(command, **ssh_options)
      @options.merge! ssh_options

      outcome = begin
        output = @ssh.ssh(@hostname, command, ssh_options, &ssh_block)
        Screenplay::Outcome.new(output)
      rescue Net::SSH::Simple::Error => ex
        log "Net::SSH::Simple::Error raised.  Using options: #{@options}"
        Screenplay::Outcome.new(ex, :failed)
      end

      log "SSH run outcome: #{outcome}"
      outcome
    end

    # Uploads +source+ file to the +destination+ path on the remote box.
    #
    # @param [String] source The source file to upload.
    # @param [String] destination The destination path to upload to.
    # @param [Hash] ssh_options Net::SSH::Simple options.  These will get merged
    #   with options set in #initialize and via #set.  Can be used to override
    #   those settings as well.
    # @return [Screenplay::Outcome]
    def upload(source, destination, **ssh_options)
      @options.merge! ssh_options

      outcome = begin
        @ssh.scp_ul(@hostname, source, destination, ssh_options, &ssh_block)
        Screenplay::Outcome.new(output)
      rescue Net::SSH::Simple::Error => ex
        log "Net::SSH::Simple::Error raised.  Using options: #{@options}"
        Screenplay::Outcome.new(ex, :failed)
      end

      log "SCP upload outcome: #{outcome}"
      outcome
    end

    private

    # DRYed up block to hand over to SSH commands for keeping handling of stdout
    # and stderr output.
    #
    # @return [Lambda]
    def ssh_block
      @ssh_block ||= lambda do |event, _, data|
        case event
        when :start
          log 'Starting SSH command...'
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
    end
  end
end
