class Drama
  class Part
    def self.act(host, **options)
      new(host, **options)
    end

    attr_reader :host

    def initialize(host, **options)
      @host = host
      options.empty? ? act : act(**options)
    end

    def method_missing(meth, *args, **options)
      super unless @host.respond_to?(meth)

      @host.send(meth, *args, **options)
    end
  end
end
