require_relative 'logger'


class Drama
  attr_reader :hostname

  class HostEnvironment
    include LogSwitch::Mixin

    UNAME_METHODS = %i[operating_system kernel_version architecture]
    DISTRIBUTION_METHODS = %i[distribution distribution_version]

    def initialize(ssh, ssh_hostname)
      @ssh = ssh
      @ssh_hostname = ssh_hostname

      @operating_system = nil
      @kernel_version = nil
      @architecture = nil

      @distribution = nil
      @distribution_version = nil

      @shell = nil
    end

    def method_missing(meth, *args)
      if UNAME_METHODS.include? meth
        unless @operating_system && @kernel_version && @architecture
          command = 'uname -a'
          result = @ssh.ssh(@ssh_hostname, command)
          extract_os(result)
        end
      elsif DISTRIBUTION_METHODS.include? meth
        unless @distribution && @distribution_version
          command = case operating_system
          when :linux
            'lsb_release --description'
          when :darwin
            'sw_vers'
          end

          result = @ssh.ssh(@ssh_hostname, command)
          extract_distribution(result)
        end
      else
        super
      end

      instance_variable_get("@#{meth}".to_sym)
    end

    def shell
      return @shell if @shell

      command = 'echo $SHELL'
      result = @ssh.ssh(@ssh_hostname, command)
      log "STDOUT: #{result.stdout}"
      %r[(?<shell>[a-z]+)$] =~ result.stdout
      @shell = shell.to_sym
    end

    private

    def extract_os(ssh_result)
      log "STDOUT: #{ssh_result.stdout}"

      %r[^(?<os>[a-zA-Z]+) (?<uname>.*)] =~ ssh_result.stdout
      @operating_system = os.downcase.to_sym

      case @operating_system
      when :darwin
        %r[Kernel Version (?<version>\d\d\.\d\d?\.\d\d?).*RELEASE_(?<arch>\S+)] =~ uname
      when :linux
        %r[\S+\s\S+(?<version>\S+).*(?<arch>\S+) GNU/Linux] =~ uname
      end

      @kernel_version = version
      @architecture = arch.downcase.to_sym
    end

    def extract_distribution(ssh_result)
      log "STDOUT: #{ssh_result.stdout}"

      case @operating_system
      when :darwin
        %r[ProductVersion:\s+(?<version>\S+)] =~ ssh_result.stdout
        distro = :osx
      when :linux
        %r[^Description:\s+(?<distro>[a-zA-Z]+)\s+release(?<version>\S+)] =~ ssh_result.stdout
      end

      @distribution = distro.downcase.to_sym
      @distribution_version = version
    end
  end
end
