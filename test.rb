require './lib/screenplay'
require 'screenplay/parts/mysql_server'

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
  #},
  'localhost' => {
    user: 'sloveless'
  },
  #'192.168.33.100' => {
  #  user: 'vagrant',
  #  password: 'vagrant',
  #  keys: [Dir.home + '.vagrantd/insecure_private_key'],
  #  host_alias: :centos55
  #},
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
  #host.play_part MySQLServer, root_password: 'meow'
  host.directory('/tmp/pants')
end

puts 'Done sketching'

#Screenplay.rollback(hosts)

