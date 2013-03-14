require 'net/scp'


class Maker
  module Commands

    def apt(**options)
      puts "Got options: #{options}"

      action = case options[:state]
      when :latest then 'install'
        # install should just check to see if it's installed, not always install it
      when :installed then 'install'
      when :removed then 'remove'
      end

      @commands << "apt-get #{action}"
    end

    def brew(**options)
      puts "Got options: #{options}"

      action = case options[:state]
      when :latest then 'upgrade'
      when :installed then 'install'
      when :removed then 'remove'
      end

      prefix = if options[:prefix]
        options[:prefix][-1] == '/' ? options[:prefix][0...-1] : options[:prefix]
      else
        '/usr/local/bin'
      end

      cmd = ''
      cmd << "#{prefix}/brew update && " if options[:update]
      cmd << "#{prefix}/brew #{action} #{options[:pkg]}"
      cmd << ' --force' if options[:force]

      @commands << cmd
    end

    def file(**options)
      puts "Got options: #{options}"

      action = case options[:state]
      when :absent then 'rm -rf'
      when :dir then 'mkdir -p'
      end

      cmd = ''
      cmd << "#{action} #{options[:path]}"
      cmd << ' --force' if options[:force]

      @commands << cmd
    end

    def script(path, **options)
      cmd = ''

      remote_file = "/tmp/maker.#{Time.now.to_i}"
      Net::SCP.upload!(@hostname, options[:user], path, remote_file)
      cmd << "chmod +x #{remote_file} && #{remote_file}"

      @commands << cmd
    end

    def shell(cmd)
      @commands << cmd
    end

    def subversion(**options)
      prefix = if options[:prefix]
        options[:prefix][-1] == '/' ? options[:prefix][0...-1] : options[:prefix]
      else
        '/usr/bin/env svn'
      end

      cmd = ''
      cmd << file_exists?(options[:dest]) + ' && '
      cmd << "#{prefix} update #{options[:dest]} || "
      cmd << "#{prefix} checkout #{options[:repo]} #{options[:dest]}"

      @commands << cmd
    end

    private

    def file_exists?(path)
      "[ -f #{path} ]"
    end
  end
end
