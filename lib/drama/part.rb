class Drama
  class Part
    def self.act(actor, **options)
      new(actor, **options)
    end

    def initialize(actor, **options)
      @actor = actor
      act(**options)
    end

    def method_missing(meth, *args, **options, &block)
      super unless @actor.respond_to?(meth)

      @actor.send(meth, *args, **options, &block)
    end
  end
end
