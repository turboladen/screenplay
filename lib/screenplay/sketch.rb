require 'yaml'
require 'rosh'
require_relative 'host'
require_relative 'part'


class Screenplay
  class Sketch
    attr_reader :hosts

    def initialize(hosts, on_fail, cmd_history_file=nil)
      @hosts = []
      @on_fail_block = on_fail
      @cmd_history_file = cmd_history_file

      hosts.each do |hostname, options|
        host_alias = options.delete(:alias)

        Rosh.add_host(hostname, host_alias: host_alias, **options)
      end

      Rosh.hosts.each do |hostname, host|
        puts "Adding host: #{hostname}"
        @hosts << Screenplay::Host.new(host, &on_fail)
      end
    end

    def action!
      starting_dir = Dir.pwd

      @hosts.each do |host|
        yield host

        time = Time.now.strftime('%Y%m%d%H%M%S')
        file = "#{host.hostname}-#{time}_changes.yml"

        File.open(file, 'w') do |f|
          YAML.dump(host.host_changes, f)
          puts "Changes for '#{host.hostname}' written to #{file}"
        end
      end

      Dir.chdir(starting_dir)
      dump_history if @cmd_history_file
    end

    def dump_history
      host_history = []

      File.open(File.expand_path(@cmd_history_file), 'w') do |f|
        sketcher.hosts.each do |host|
          host_history << {
            hostname: host.hostname,
            history: host.shell.history
          }

          YAML.dump(host_history, f)
        end
      end
    end
  end
end
