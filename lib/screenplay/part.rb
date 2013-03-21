class Screenplay
  # Parts are a simple mechanism for allowing you to create your own grouping of
  # actions, usually to accomplish some task.  Think of it like a script that
  # you can pass in some options to and call from other scripts.  This is
  # similar to a Puppet Module, Chef Cookbook, or Ansible Playbook.
  #
  # You might, for example, want a Part that installs rbenv, RVM, or just plain
  # old Ruby built from scratch.  You can create a Part for one (or all), then
  # stash it somewhere that Screenplay has access to, require it wherever you're
  # using a Screenplay::Host, and the Host can then run all of the actions in
  # the Part, simply by calling #play_part on the Host object.
  #
  # The only requirement for your Parts are that they a) inherit from this class
  # and b) define a #play method.
  #
  # There is a gem of popular Parts, +screenplay-parts+ that might be useful to
  # you...
  #
  # @example A partial MySQL part
  #
  #   # A port of Opscode's MySQL Server Part could look something like:
  #   class MySQL < Screenplay::Part
  #     # Define this here, or in some other file.  And use some other Ruby
  #     # feature other than a constant--it's up to you.
  #     PACKAGES = {
  #       debian: 'mysql-server',
  #       rhel: 'mysql-server',
  #       fedora: 'mysql-server',
  #       centos: 'mysql-server',
  #     }
  #
  #     def play(root_group: 'root', conf_dir: '/etc/mysql', package: PACKAGES[host.env.distribution])
  #       case host.env.operating_system
  #       when :linux
  #         case host.env.distribution
  #         when :ubuntu
  #           preseeding_dir = '/var/cache/local/preseeding'
  #           preseeding_file = "#{preseeding_dir}/mysql-server.seed"
  #
  #           host.directory path: preseeding_dir, owner: 'root', group: root_group, mode: '0755'
  #           host.template path: preseeding_file, source: 'mysql-server.seed.erb',
  #             owner: 'root', group: root_group, mode: '0600'
  #           host.shell command: "debconf-set-selections #{preseeding_file}"
  #           host.template path: "#{conf_dir}/debian.cnf", source: 'mysql-server.seed.erb',
  #             owner: 'root', group: root_group, mode: '0600'
  #
  #           host.apt package: PACKAGES[host.env.distribution]
  #         when :centos
  #           # Etc
  #         end
  #       when :darwin
  #           # Etc
  #       end
  #
  #     end
  #
  #     # Add any helper methods too, if you want to refactor #play...
  #   end
  #
  #   # Then your Host object could use that by:
  #
  #   host = Screenplay::Host.new('localhost')
  #
  #   # Use the default values defined for MySQL#play
  #   host.play_part MySQL
  #
  #   # Pass in other values
  #   host.play_part MySQL, conf_dir: '/opt/mysql/conf', root_group: 'admin'
  class Part

    # @param [Screenplay::Host] host The host that should play the part.
    # @param [Hash] options Any options to pass on to the user-defined Part's
    #   #play method.
    def self.play(host, **options)
      new(host, **options)
    end

    # @return [Screenplay::Host] Allows child objects easy access to a Host
    #   object and its methods from within the Part.
    attr_reader :host

    # @param [Screenplay::Host] host The host that should play the part.
    # @param [Hash] options Any options to pass on to the user-defined Part's
    #   #play method.
    def initialize(host, **options)
      @host = host
      options.empty? ? play : play(**options)
    end
  end
end
