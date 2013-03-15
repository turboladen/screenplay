require 'net/scp'


class Maker
  module Commands
    def subversion(
      repo: repo,
      dest: dest,
      prefix: '/usr/bin/env svn'
      )
      cmd = ''
      cmd << file_exists?(dest) + ' && '
      cmd << "#{prefix} update #{dest} || "
      cmd << "#{prefix} checkout #{repo} #{dest}"

      @commands << cmd
    end

    private

    def file_exists?(path)
      "[ -f #{path} ]"
    end
  end
end
