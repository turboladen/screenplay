require_relative 'logger'


class Drama
  class Outcome < Hash
    include LogSwitch::Mixin

    attr_reader :ssh_output
    attr_reader :status

    def initialize(ssh_output, status=nil)
      super()

      @status = status
      self[:status] = @status

      @ssh_output = ssh_output
      log "SSH output: #{@ssh_output}"

      if @ssh_output.is_a? Net::SSH::Simple::Error
        raise @ssh_output
      else
        @ssh_output.each { |k, v| self[k.to_sym] = v }
      end
    end

    def error?
      @ssh_output.is_a? Net::SSH::Simple::Error
    end

    def status=(new_status)
      @status = new_status
      self[:status] = @status
    end
  end
end
