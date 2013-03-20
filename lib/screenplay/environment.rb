class Screenplay
  class Environment
    def self.stages
      @stages ||= []
    end

    def self.hosts
      @hosts ||= {}
    end
  end
end
