require 'rosh'
require_relative 'screenplay/host'
require_relative 'screenplay/part'


class Screenplay
  def self.sketch(hosts, on_fail: nil,
    report_file: nil, &block)
    sketcher = new(hosts, on_fail)

    starting_dir = Dir.pwd
    sketcher.sketch(&block)
    Dir.chdir(starting_dir)

    if report_file
      require 'yaml'

      File.open(File.expand_path(report_file), 'w') do |f|
        sketcher.hosts.each do |host|
          YAML.dump(host.shell.history, f)
        end
      end
    else
      sketcher.hosts.each do |host|
        puts "History for #{host.hostname}"
        p host.shell.history
      end
    end
  end

  attr_reader :hosts

  def initialize(hosts, on_fail)
    @hosts = []
    @on_fail_block = on_fail

    rosh = Rosh.new

    hosts.each do |hostname, options|
      host_alias = options.delete(:alias)

      rosh.add_host(hostname, host_alias: host_alias, **options)
    end

    rosh.hosts.each do |hostname, host|
      puts "Adding host: #{hostname}"
      @hosts << Screenplay::Host.new(host, &on_fail)
    end
  end

  def sketch
    @hosts.each do |host|
      yield host
    end
  end
end

#require_relative 'screenplay/logger'
#require_relative 'screenplay/environment'
#require_relative 'screenplay/stage'
#require_relative 'screenplay/host'
#require_relative 'screenplay/version'
