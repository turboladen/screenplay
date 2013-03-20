class Screenplay
  class Part
    def self.play(host, **options)
      new(host, **options)
    end

    attr_reader :host

    def initialize(host, **options)
      @host = host
      options.empty? ? play : play(**options)
    end

    def method_missing(meth, *args, **options)
      super unless @host.respond_to?(meth)

      @host.send(meth, *args, **options)
    end
  end
end
