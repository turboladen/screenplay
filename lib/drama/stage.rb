require_relative 'host'


class Drama
  module Stage
    def self.included(base)
      Drama.stages << base.to_s.downcase.split('::').last
    end

    def action!
      @host_group.each do |name, host|
        puts "Acting on host #{name}..."
        host.action!
      end
    end
  end
end
