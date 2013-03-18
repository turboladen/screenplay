class Drama
  class Part
    def self.act(actor, **options)
      new(actor, **options)
    end

    def initialize(actor, **options)
      @actor = actor
      if options.empty?
        act
      else
        act(**options)
      end
    end

    def method_missing(meth, *args, **options)
      super unless @actor.respond_to?(meth)

      @actor.send(meth, *args, **options)
    end
  end
end
