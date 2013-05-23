require './lib/screenplay'

=begin
hosts = {
  'localhost' => {
    username: 'Steveloveless',
    alias: :local
  }
}

report_file = 'test_result.yml'

Screenplay.sketch(hosts, stop_on_fail: false, report_file: report_file) do |host|
  host.packages.update
  host.packages['rbenv'].install version: '0.4.0'
  host.packages['ruby-build'].install
end
=end

#   # A port of Opscode's MySQL Server Part could look something like:
class MySQL < Screenplay::Part
  # Define this here, or in some other file.  And use some other Ruby
  # feature other than a constant--it's up to you.
  PACKAGES = {
    debian: 'mysql-server',
    ubuntu: 'mysql-server',
    rhel: 'mysql-server',
    fedora: 'mysql-server',
    centos: 'mysql-server',
  }

  def play(root_group: 'root', conf_dir: '/etc/mysql', package: PACKAGES[host.distribution])
    case host.operating_system
    when :linux
      #case host.distribution
      #when :ubuntu
        preseeding_dir = '/var/cache/local/preseeding'
        preseeding_file = "#{preseeding_dir}/mysql-server.seed"

        host.shell.su do
          host.directory preseeding_dir, owner: 'root', group: root_group, mode: '755'

          host.file preseeding_file, owner: 'root', group: root_group, mode: '755',
            contents: lambda { |file|
              file.from_template('mysql-server.seed.erb', name: 'Bob!')
            }

          host.packages.update_index
          host.packages.upgrade_packages
        end
      #when :centos
        # Etc
      #end
    when :darwin
        # Etc
    end
  end

  # Add any helper methods too, if you want to refactor #play...
end

# Then your Host object could use that by:

#host = Screenplay::Host.new('localhost')

# Use the default values defined for MySQL#play
#host.play_part MySQL

# Pass in other values
#host.play_part MySQL, conf_dir: '/opt/mysql/conf', root_group: 'admin'

hosts = {
  #'sloveless-lin.pelco.org' => {
  #  user: 'sloveless',
  #  alias: :lin
  #}
  '192.168.33.100' => {
    user: 'vagrant',
    password: 'vagrant',
    keys: [Dir.home + '.vagrantd/insecure_private_key'],
    host_alias: :centos55
  },
  #'192.168.33.110' => {
  #  user: 'vagrant',
  #  password: 'vagrant',
  #  keys: [Dir.home + '.vagrantd/insecure_private_key'],
  #  host_alias: :ubuntu
  #},
  #'192.168.33.105' => {
  #  user: 'vagrant',
  #  password: 'vagrant',
  #  keys: [Dir.home + '.vagrantd/insecure_private_key'],
  #  host_alias: :gentoo
  #}
}

cmd_history = 'cmd_history.yml'

Screenplay.sketch(hosts, cmd_history_file: cmd_history) do |host|
  host.play_part MySQL
end

puts 'Done sketching'

Screenplay.rollback(hosts)

