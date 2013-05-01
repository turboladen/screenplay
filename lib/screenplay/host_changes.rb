class Screenplay
  class HostChanges
    def initialize
      @changes = []
    end

    def update(object, attribute: attribute, old: old, new: new)
      @changes << { object: object, attribute: attribute, old: old, new: new }
    end
  end
end
