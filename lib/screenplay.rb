require 'yaml'
require_relative 'screenplay/sketch'


class Screenplay

  # Defines a "sketch" to be executed against all +hosts+.  A sketch is a method
  # provided by Screenplay for describing a set of hosts, where the focus for
  # describing the hosts is via specifying direct objects, their state, and
  # additional commands.
  #
  # @param [Hash{ String => Hash}] hosts Keys are hostnames/IP addresses and
  #   values are options to pass on the Rosh::Host.
  #
  # @param on_fail
  #
  # @param [String] cmd_history_file Path to output the list of commands that
  #   were executed throughout the sketch.
  def self.sketch(hosts, on_fail: nil, cmd_history_file: nil, &block)
    sketcher = Sketch.new(hosts, on_fail, cmd_history_file)
    sketcher.action!(&block)
  end

  # @param [Array] change_files List of files to use for rewinding.
  def self.rewind(change_files)
    change_files.each do |file|
      changes = YAML.load_file(file)
      changes.rewind
    end
  end
end

#require_relative 'screenplay/logger'
#require_relative 'screenplay/environment'
#require_relative 'screenplay/stage'
#require_relative 'screenplay/host'
#require_relative 'screenplay/version'
