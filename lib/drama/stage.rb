require_relative 'host'
require_relative 'environment'
require_relative 'logger'


class Screenplay
  module Stage
    def self.included(base)
      Screenplay::Environment.stages << base.to_s.downcase.split('::').last
    end

    attr_reader :host_group

    def action!
      @host_group.each do |name, host|
        host.action!
      end
    end
  end
end
