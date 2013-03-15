require_relative '../action'


class Maker
  module Actions
    class Brew < Maker::Action
      def initialize(ssh, host,
        pkg: pkg,
        state: :installed,
        update: false,
        prefix: '/usr/local/bin/brew',
        force: false)
        @ssh = ssh
        @host = host

        action = case state
        when :latest then 'upgrade'
        when :installed then 'install'
        when :removed then 'remove'
        end

        @command = ''
        @command << "#{prefix} update && "  if update
        @command << "#{prefix} #{action} #{pkg}"
        @command << ' --force'                   if force
      end

      # @return [Hash]
      def run
        begin
          output = @ssh.ssh @host, @command
        rescue Net::SSH::Simple::Error => ex
          Maker::Outcome.new(ex, :failed)
        end

        status = case output.exit_code
        when 0
          puts "Maker finished: '#{output.cmd}'".green
          :updated
        when 1
          if output.stdout.match /already installed/
            :no_change
          else
            :failed
          end
        else
          plan_failure(r, start_time)
        end

        Maker::Outcome.new(output, status)
      end
    end
  end
end
