require_relative '../action'


class Drama
  module Actions
    class Subversion < Drama::Action
      def initialize(
        repo: repo,
        dest: dest,
        prefix: '/usr/bin/env svn'
      )
        super()
        @dest = dest

        @command << file_exists?(@dest) + ' && '
        @command << "#{prefix} update #{@dest} || "
        @command << "#{prefix} checkout #{repo} #{@dest}"
      end

      def call(ssh, host)
        outcome = super(ssh, host)
        return outcome if outcome.exception?

        outcome.status = case outcome.ssh_output.exit_code
        when 0
          if outcome.ssh_output.stdout.match /[A-Za-z]\s+#{@dest}/m
            :updated
          else
            :no_change
          end
        else
          :failed
        end

        outcome
      end
    end
  end
end
