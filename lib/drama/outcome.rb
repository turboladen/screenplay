class Drama
  class Outcome < Hash
    attr_reader :status
    attr_reader :ssh_output

    def initialize(ssh_output, status=nil)
      super()

      @status = status
      self[:status] = @status

      @ssh_output = ssh_output

      if @ssh_output.is_a? Net::SSH::Simple::Error
      else
        @ssh_output.each { |k, v| self[k.to_sym] = v }
      end
    end

    def status=(new_status)
      @status = new_status
      self[:status] = @status
    end

    def exception?
      has_key?(:exit_status)
    end
  end
end
