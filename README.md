screenplay
=====

* <http://github.com/turboladen/screenplay>

DESCRIPTION:
------------

Simple Configuration Management that _really_ lets you use Ruby.

FEATURES/PROBLEMS:
------------------

* FIX (list of features or problems)

SYNOPSIS:
---------

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
  able to do anything to that box using standard tools already on the box (like
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


### Basic Actions ###

Actions available:
* apt
* brew
* file
* script
* shell
* subversion

    %w[git-core curl openssl].each do |package|
      Screenplay.apt pkg: package, state: :installed, update_cache: true
    end

### Scenes ###

(Not yet implemented, but should look something like this...)

    # rbenv.rb
    class RbEnv < Screenplay::Scene
      def act
        if remote_os.osx?
          brew pkg: 'git', state: :installed, update: true
          brew pkg: 'rbenv', state: :installed
          brew pkg: 'ruby-build', state: :installed
          return
        end

        profile_file =  if remote_os.ubuntu?
          '~/.profile'
        elsif remote_shell.zsh?
          '~/.zshrc'
        else
          '~/.bash_profile'
        end

        rbenv_home = "/home/#{user}/.rbenv"

        # git
        apt pkg: 'git', state: :installed, update_cache: true

        # rbenv
        git repo: 'git://github.com/sstephenson/rbenv.git', dest: rbenv_home
        shell %[echo 'export PATH="#{rbenv_home}/bin:$PATH"' >> #{profile_file}]
        shell %[echo 'eval "$(rbenv init -)"' >> #{profile_file}]

        # ruby-build
        git repo: 'git://github.com/sstephenson/ruby-build.git',
          dest: "#{rbenv_home}/plugins/ruby-build"
      end
    end


    # setup_my_stuff.rb
    require 'rbenv.rb'

    Screenplay.add_scene(RbEnv, host: '10.1.2.3', user: 'george')


    # From the shell...
    $ screenplay setup_my_stuff.rb

REQUIREMENTS:
-------------

* Ruby 2.0.0
* RubyGems
  * blockenspiel
  * colorize
  * highline
  * net-ssh-simple

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
