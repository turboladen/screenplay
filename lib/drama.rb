abort('Must use Ruby 2.0.0 or greater with drama.') if RUBY_VERSION < '2.0.0'

class Drama
end

require_relative 'drama/logger'
require_relative 'drama/screenplay'
require_relative 'drama/version'
