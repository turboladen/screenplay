class Maker
  class Outcome < Hash
    attr_reader :status
    attr_reader :ssh_output

    def initialize(ssh_output, status)
      @ssh_output = ssh_output
      @status = status

      super()

      @ssh_output.each do |k, v|
        self[k.to_sym] = v
      end

      self[:status] = @status
    end
  end
end
