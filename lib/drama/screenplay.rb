require 'blockenspiel'
require_relative 'host'
require_relative 'logger'


class Drama
  class Screenplay
    include Blockenspiel::DSL
    include LogSwitch::Mixin

    def self.write(stage=nil, &block)
      screenplay = new(stage)
      Blockenspiel.invoke(block, screenplay)
      screenplay
    end

    attr_reader :actors
    attr_reader :stages

    def initialize(stage)
      @actors = []
      @stages = {}
      @stage = stage
      log 'Initialized'
    end

    def action!
      @actors.each do |actor|
        log "Kicking off acting for actor: #{@actors.last.config[:host]}"
        actor.action!
      end
    end

    def act_on(host, actor_options={}, &block)
      actor = if host == :stage
        Drama::Host.act_on(@stages[@stage], &block)
      else
        Drama::Host.act_on(host, &block)
      end

      actor.config.merge!(actor_options)
      log "Added Host for host: #{actor.config[:host]}"

      @actors << actor
    end

    def stage(name_and_host)
      log "Adding stage: #{name_and_host}"
      @stages.merge! name_and_host
    end

    def get_binding
      binding
    end
  end
end
