require 'etc'
require 'blockenspiel'
require 'colorize'
require 'net/ssh/simple'
require_relative 'commands'


class Maker
  class Runner
    include Blockenspiel::DSL
    include Maker::Commands

    def self.run(&block)
      Blockenspiel.invoke(block, new)
    end

    def initialize
      @commands = []
      @user ||= Etc.getlogin
    end

    def host(hostname)
      @hostname = hostname
    end

    def ssh_key_path(path=nil)
      @ssh_key_path = path if path

      @ssh_key_path
    end

    def user(user)
      @user = user
    end

    def run_commands
      abort('Must use Ruby 2.0.0 or greater with maker.') if RUBY_VERSION < '2.0.0'
      start_time = Time.now

      Net::SSH::Simple.sync do
        @commands.each do |cmd|
          puts "executing command: '#{cmd}' as user #{@user} on #{@hostname}".blue

          options = {
            user: @user,
          #  verbose: :debug
          }

          options.merge!(keys: ssh_key_path) if ssh_key_path
          r = ssh(@hostname, cmd, options)

          if r.exit_code.zero?
            puts "Maker finished: '#{r.cmd}'".green
          else
            error = <<-ERROR
*** Maker Error! ***
Plan failed: #{r.cmd}
Exit code: #{r.exit_code}
Plan Duration: #{r.finish_at - r.start_at}
Total Duration: #{r.finish_at - start_time}
STDERR: #{r.stderr}
            ERROR

            abort(error.red)
          end
        end
      end

      puts "Maker finished making\nTotal Duration: #{Time.now - start_time}".green
    end

    def get_binding
      binding
    end
  end
end
