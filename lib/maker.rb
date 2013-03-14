require 'blockenspiel'
require 'colorize'
require 'open4'
require_relative 'maker/commands'


class MakerCommands
  include Blockenspiel::DSL
  include Open4
  include Maker::Commands

  def initialize
    @commands = []
  end

  def ssh
    "ssh #{@hostname}"
  end

  def host(hostname)
    @hostname = hostname
  end

  def sudo_prompt
    /^Password:/
  end

  def sudo_password
    state = `stty -g`
    abort 'stty(1) not found' unless $?.success?

    begin
      system 'stty -echo'
      $stdout.print 'sudo password: '
      $stdout.flush
      password = $stdin.gets
      $stdout.puts
    ensure
      system "stty #{state}"
    end

    password
  end

  def run_commands
    result = []
    cmd = ssh + ' '
    cmd << "'#{@commands.flatten.join(' && ')}'"
    puts "Running command: #{cmd}"
    pid, inn, out, err = popen4(cmd)

    inn.sync   = true
    streams    = [out, err]
    out_stream = {
      out => $stdout,
      err => $stderr,
    }

    # Handle process termination ourselves
    status = nil
    Thread.start do
      status = Process.waitpid2(pid).last
    end

    until streams.empty? do
      # don't busy loop
      selected, = select streams, nil, nil, 0.1

      next if selected.nil? or selected.empty?

      selected.each do |stream|
        if stream.eof? then
          streams.delete stream if status # we've quit, so no more writing
          next
        end

        data = stream.readpartial(1024)
        out_stream[stream].write data.blue

        if stream == err and data =~ sudo_prompt then
          inn.puts sudo_password
          data << "\n"
          $stderr.write "\n"
        end

        result << data
      end
    end

    unless status.success?
      abort "execution failed with status #{status.exitstatus}: #{cmd}"
    end

    result.join
  ensure
    inn.close rescue nil
    out.close rescue nil
    err.close rescue nil
  end
end

class Maker
  def self.run(&block)
    Blockenspiel.invoke(block, MakerCommands.new)
  end
end
