class Screenplay
  class HostChanges
    def initialize
      @changes = []
    end

    def update(*args)
      puts "update called with #{args}"
      @changes << args
    end
  end
end
