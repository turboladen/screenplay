require_relative 'host'
require_relative 'environment'
require_relative 'logger'


class Drama
  module Stage
    def self.included(base)
      Drama::Environment.stages << base.to_s.downcase.split('::').last
    end

    attr_reader :host_group

    def action!
      @host_group.each do |name, host|
        host.action!
      end
    end
  end
end
