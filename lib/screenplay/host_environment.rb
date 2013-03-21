require_relative 'logger'
require_relative 'environment'


class Screenplay
  attr_reader :ssh_hostname

  class HostEnvironment
    include LogSwitch::Mixin

    UNAME_METHODS = %i[operating_system kernel_version architecture]
    DISTRIBUTION_METHODS = %i[distribution distribution_version]

    UNAME_METHODS.each do |meth|
      define_method(meth) do
        unless @operating_system && @kernel_version && @architecture
          command = 'uname -a'
          result = Screenplay::Environment.hosts[@ssh_hostname].ssh.run(command)
          extract_os(result)
        end

        instance_variable_get("@#{meth}".to_sym)
      end
    end

    DISTRIBUTION_METHODS.each do |meth|
      define_method(meth) do
        unless @distribution && @distribution_version
          command = case self.operating_system
          when :linux
            'lsb_release --description'
          when :darwin
            'sw_vers'
          end

          result = Screenplay::Environment.hosts[@ssh_hostname].ssh.run(command)
          extract_distribution(result)
        end

        instance_variable_get("@#{meth}".to_sym)
      end
    end

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

    def shell
      return @shell if @shell

      command = 'echo $SHELL'
      result = Screenplay::Environment.hosts[@ssh_hostname].ssh.run(command)
      log "STDOUT: #{result.ssh_output.stdout}"
      %r[(?<shell>[a-z]+)$] =~ result.ssh_output.stdout
      @shell = shell.to_sym
    end

    private

    def extract_os(result)
      log "STDOUT: #{result.ssh_output.stdout}"

      %r[^(?<os>[a-zA-Z]+) (?<uname>.*)] =~ result.ssh_output.stdout
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

    def extract_distribution(result)
      log "STDOUT: #{result.ssh_output.stdout}"

      case @operating_system
      when :darwin
        %r[ProductVersion:\s+(?<version>\S+)] =~ result.ssh_output.stdout
        distro = :osx
      when :linux
        %r[Description:\s+(?<distro>\w+)\s+release\s+(?<version>\S+)] =~ result.ssh_output.stdout
      end

      @distribution = distro.downcase.to_sym
      @distribution_version = version
    end
  end
end
