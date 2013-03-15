require 'net/scp'


class Maker
  module Commands
    def script(
      source_file,
      args: nil,
      user: @user
      )
      remote_file = "/tmp/maker.#{Time.now.to_i}"
      cmd = ''

      source_file = File.expand_path(source_file)
      puts "Uploading #{source_file} to #{@host}:#{remote_file} as #{user}"
      ssh = Net::SSH::Simple.new(ssh_options)

      #begin
        @commands << proc { ssh.scp_ul @host, source_file, remote_file }
      #rescue Net::SSH::Simple::Error => ex
      #  maker_failure(ex)
      #end

      cmd << "chmod +x #{remote_file} && #{remote_file}"
      cmd << " #{args}" if args

      @commands << cmd
    end

    def shell(cmd)
      @commands << cmd
    end

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
