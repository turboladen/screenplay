require_relative 'logger'


class Drama
  attr_reader :hostname

  class HostEnvironment
    include LogSwitch::Mixin

    UNAME_METHODS = %i[operating_system kernel_version architecture]

    def initialize(ssh, ssh_hostname)
      @ssh = ssh
      @ssh_hostname = ssh_hostname
    end

    def method_missing(meth, *args)
      super unless UNAME_METHODS.include? meth

      unless @operating_system && @kernel_version && @architecture
        command = 'uname -a'
        result = @ssh.ssh(@ssh_hostname, command)
        extract_os(result)
      end

      instance_variable_get("@#{meth}".to_sym)
    end

    private

    def extract_os(ssh_result)
      log "STDOUT: #{ssh_result.stdout}"

      %r[^(?<os>[a-zA-Z]+) (?<uname>.*)] =~ ssh_result.stdout
      @operating_system = os.downcase.to_sym

      if @operating_system == :darwin
        %r[Kernel Version (?<version>\d\d\.\d\d?\.\d\d?).*RELEASE_(?<arch>\S+)] =~ uname
        @kernel_version = version
        @architecture = arch.downcase.to_sym
      elsif @operating_system == :linux
        %r[\S+\s\S+(?<version>\S+).*(?<arch>\S+) GNU/Linux] =~ uname
        @kernel_version = version
        @architecture = arch.downcase.to_sym
      end
    end
  end
end
