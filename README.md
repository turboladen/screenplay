screenplay
=====

* <http://github.com/turboladen/screenplay>

DESCRIPTION:
------------

Simple Configuration Management that _really_ lets you use Ruby.

Your app is not just your code--it's all of its dependencies as well--so you
should be able to manage those dependencies as part of your app.  When you
deploy, you should (at least have the option to) make sure your host(s) are in
the state that you want them to be in: a nice, happy place for all of your
codez.

FEATURES/PROBLEMS:
------------------

* Manage local or remote:
    * files (static or from a template), directories, links
    * users & groups
    * packages:
        * apt & deb
        * yum & rpm
        * brew
    * source code repositories:
        * git
        * subversion
* Run scripts/commands
* "sketches" for reusing things you do regularly


SYNOPSIS:
---------

Screenplay uses [ROSH](https://github.com/turboladen/rosh) (Ruby Object SHell)
for running commands both locally or remotely, thus if you can do something with
that, there's a good chance you can do it with screenplay.

### Why another configuration management tool? ###

[Puppet](https://puppetlabs.com), [Chef](http://www.opscode.com/chef/),
[Ansible](http://ansible.cc) and others are all super cool, but they never quite
let me solve problems the way I wanted to: super easily.

Gripes with those tools:

* I don't want to have to figure out how to install the tool and it's
  dependencies. RubyGems and Bundler are great for managing these sorts of
  things--why not just use those?
    * Others:
        * Ansible: 0
        * Chef: -1
        * Puppet: -1
    * Screenplay:
        * Just `gem install screenplay` on the box you want to run from.
* I don't want to have to set anything up on the boxes I manage.  I should be
  able to do anything to that box using standard tools already on the box (aka
  SSH).
    * Others:
        * Ansible: +1
        * Chef: -1
        * Puppet: -1
    * Screenplay:
        * Does everything over SSH.
* I want to install the tool from the box I'm going to run stuff from and that's
  it.  Reading tons of docs and setting up different boxes always seemed
  overbearing for my purposes.
    * Others:
        * Ansible: +1
        * Chef: +1 (chef-solo)
        * Puppet: -1
    * Screenplay:
        * Just `gem install screenplay` on the box you want to run from.
        * "Scenes" (Screenplay's modules/manifests, cookbooks/recipes, playbooks) are
          pulled in from a local or remote path.  How you get the scenes there is
          up to you (use git, svn, ftp, scp, whatever).
* I want to use a programming language for defining what it is I want to do.
  GPLs exist for solving problems--why make us learn another language just to
  solve these types of problems?  And using a markup language for defining this
  stuff is _super_ handy--until you want to use any sort of logic, and then it
  just feels contrived.
    * Others:
        * Ansible: -1
        * Chef: +1
        * Puppet: -1
    * Screenplay:
        * Just Ruby with a little DSL niceness (but not too much).

Other important things that the other tools also solve:

* My app's configuration should live with my app.  Everyone working on the app
  should have access to updating the app's dependencies as the app needs.
* My app's configuration should be able to be applied to any host--local or
  remote, virtual or real--without having to specify any fancy info.
* I don't want to have to rely on a "server" implementation to pull
  scripts/recipes/whatever from--there are good tools that already solve this
  problem.


### Sketches ###

A Sketch is a set of descriptions to be applied to a host or set of hosts.
Sketches are idempotent: if the host(s) are already in the described state, then
screenplay does nothing to the host to change it; otherwise, it will run
commands on the host(s) to make it how you've described it.

Sketch actions are simply methods called on the Host object that take a block
of setting attributes on the object you want to describe.  For example,
something simliar to a simple Capistrano deploy:

    # Declare some attributes as variables so we can reuse them.
    hosts = {
      '10.0.0.1' => {
        user: 'george',
        keys: [Dir.home + '/.ssh/id_rsa']
      }
    }

    app_root = '/var/www/my_app'
    app_owner = 'app'

    perms_block = lambda do |dir|
      dir.exists = true
      dir.owner = app_owner
      dir.group = app_owner
      dir.mode = '664'
    end

    git_repo = 'https://github.com/turboladen/my_app'

    current_dir = "#{app_root}/current"
    releases_dir = "#{app_root}/releases"
    release_dir = "#{app_root}/releases/#{Time.now.strftime('%Y%M%d%m%S')}"

    shared_dir          = "#{app_root}/shared"
    shared_bundle_dir   = "#{shared_dir}/bundle"
    shared_log_dir      = "#{shared_dir}/log"
    shared_pid_dir      = "#{shared_dir}/pid"

    # Start describing what you want on the hosts.
    Screenplay.sketch(hosts) do |host|
      # Make sure the directory structure is created.
      [
        app_root,
        releases_dir, release_dir,
        shared_dir, shared_bundle_dir, shared_log_dir, shared_pid_dir
        ].each do |dir|
        host.directory(dir, &perms_block)
      end

      # Pull down the app's source.
      host.git(git_repo) do |repo|
        repo.destination = release_dir
        repo.depth = 1
        repo.branch = 'new_features'
        repo.commit_hash = :latest
      end

      # Link release directories with shared directories.
      public_path = "#{release_dir}/public"

      %w[log bundle].each do |dir|
        host.link("#{public_path}/#{dir}") do |link|
          link.target = "#{release_dir}/#{dir}"
          link.force = true
        end
      end

      host.link(release_dir, target: current_dir)   # (Non-block form!)

      # Change the working path to be the release path.
      host.cd(release_dir)

      # Install bundler deps.
      host.bundler do |bundle|
        bundle.executable = "#{release_dir}/bin/bundler"
        bundle.gemfile = "#{release_dir}/Gemfile"
        bundle.path = "#{shared_dir}/bundle"
        bundle.options = %w[--deployment --quiet]
        bundle.without = %w[development test staging]
      end

      host.rake('deploy:assets:precompile') do |rake|
        rake.executable = "#{release_dir}/bin/rake"
        rake.with_environment_variables['RAILS_ENV'] = 'production'
        rake.with_environment_variables['RAILS_GROUPS'] = 'assets'
      end

      host.rake('db:migrate') do |rake|
        rake.executable = "#{release_dir}/bin/rake"
        rake.with_environment_variables['RAILS_ENV'] = 'production'
      end

      # Restart Passenger.
      host.exec('touch tmp/restart.txt')
    end


### Parts ###

Screenplay Parts are reusable chunks of described environment, for things that
we all do regularly.  For example, one for installing rbenv:

    # rbenv.rb
    class RbEnv < Screenplay::Part
      def play(user: user, binary: '/usr/bin/env rbenv', ruby_version: nil, remove: false)
        if remove
          remove_rvm(user)
          return
        end

        if host.env.operating_system == :darwin
          host.brew formula: 'git', state: :installed, update: true
          host.brew formula: 'rbenv', state: :installed
          host.brew formula: 'ruby-build', state: :installed
          return
        end

        profile_file = if host.env.distribution == :ubuntu
          '~/.profile'
        elsif host.env.shell == :zsh
          '~/.zshrc'
        else
          '~/.bash_profile'
        end

        rbenv_home = "/home/#{user}/.rbenv"

        # git
        case host.env.distribution
        when :ubuntu
          host.apt package: 'git', update_cache: true, sudo: true
        when :centos
          host.yum package: 'git', update_cache: true, sudo: true
        end

        # rbenv
        host.git repository: 'git://github.com/sstephenson/rbenv.git',
          destination: rbenv_home
        host.shell command: %[echo 'export PATH="#{rbenv_home}/bin:$PATH"' >> #{profile_file}]
        host.shell command: %[echo 'eval "$(rbenv init -)"' >> #{profile_file}]

        # ruby-build
        host.git repository: 'git://github.com/sstephenson/ruby-build.git',
          destination: "#{rbenv_home}/plugins/ruby-build"

        # Install ruby
        if ruby_version
          host.shell command: %[#{binary} versions | grep #{ruby_version}], on_fail: -> do
            host.shell command: %[#{binary} install #{ruby_version}]
          end
        end
      end

      def remove_rvm(user)
        case host.env.operating_system
        when :darwin
          host.brew formula: 'rbenv', state: :removed
          host.brew formula: 'ruby-build', state: :removed
        when :linux
          host.directory path: "/home/#{user}/.rbenv", state: :absent
        end
      end
    end


    # setup_my_stuff.rb
    require 'screenplay'
    require_relative 'rbenv'

    hosts = { '192.168.0.123' => { user: 'ricky', password: 'ricardo' } }

    Screenplay.sketch(hosts) do |host|
      host.play_part(RbEnv, user: 'ricky')
    end


    # From the shell...
    $ ruby setup_my_stuff.rb

Since this seems useful, there are already some parts that you can use, over in
{screenplay-parts}[http://github.com/turboladen/screenplay-parts], but feel
free to write your own!


REQUIREMENTS:
-------------

* Ruby 2.0.0
* RubyGems
  * colorize
  * gli
  * log_switch

INSTALL:
--------

* gem install screenplay

DEVELOPERS:
-----------

After checking out the source, run:

  $ rake newb

This task will install any missing dependencies, run the tests/specs,
and generate the RDoc.

LICENSE:
--------

(The MIT License)

Copyright (c) 2013 FIX

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
