abort('Must use Ruby 2.0.0 or greater with drama.') if RUBY_VERSION < '2.0.0'

class Drama
  def self.stages
    @stages ||= []
  end
end

require_relative 'drama/logger'
require_relative 'drama/stage'
require_relative 'drama/host'
require_relative 'drama/version'
