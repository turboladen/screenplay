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

    def ssh_options
      options = {
        user: @user,
        #  verbose: :debug
      }

      options.merge!(keys: ssh_key_path) if ssh_key_path

      options
    end

    def maker_failure(exception, start_time)
      error = <<-ERROR
*** Maker Error! ***
* Exception: #{exception.wrapped}
* Plan Duration: #{exception.result.finish_at - exception.result.start_at}
* Total Duration: #{exception.result.finish_at - start_time}
* SCP source: #{exception.result.opts[:scp_src]}
* SCP destination: #{exception.result.opts[:scp_dst]}
* STDERR: #{exception.result.stderr}
      ERROR

      abort(error.red)
    end

    def plan_failure(output, start_time)
      error = <<-ERROR
*** Maker Error! ***
* Plan failed: #{output.cmd}
* Exit code: #{output.exit_code}
* Plan Duration: #{output.finish_at - output.start_at}
* Total Duration: #{output.finish_at - start_time}
* STDERR: #{output.stderr}
      ERROR

      abort(error.red)
    end

    def run_commands
      abort('Must use Ruby 2.0.0 or greater with maker.') if RUBY_VERSION < '2.0.0'
      start_time = Time.now

      Net::SSH::Simple.sync do
        @commands.each do |cmd|
          puts "executing command: '#{cmd}' as user #{@user} on #{@hostname}".blue

          begin
            r = ssh(@hostname, cmd, ssh_options)
          rescue Net::SSH::Simple::Error => ex

          end

          if r.exit_code.zero?
            puts "Maker finished: '#{r.cmd}'".green
          else
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
