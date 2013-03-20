require './lib/drama/version'


Gem::Specification.new do |s| 
  s.name = 'screenplay'
  s.version = Screenplay::VERSION
  s.author = 'Steve Loveless'
  s.homepage = 'http://github.com/turboladen/screenplay'
  s.email = 'steve.loveless@gmail.com'
  s.summary = 'FIX'
  s.description = %q(FIX)

  s.required_ruby_version = '>= 2.0.0'
  s.required_rubygems_version = '>=2.0.0'
  s.files = Dir.glob('{lib,spec}/**/*') + Dir.glob('*.rdoc') +
    %w(.gemtest Gemfile screenplay.gemspec Rakefile)
  s.test_files = Dir.glob('{spec}/**/*')
  s.require_paths = ['lib']

  %w[
    colorize
    highline
    log_switch
    net-ssh-simple
  ].each(&s.method(:add_dependency))

  s.add_development_dependency 'bundler', '>= 1.0.1'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'redcarpet'
  s.add_development_dependency 'rspec', '>= 2.12.0'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'yard', '>= 0.7.2'
end
