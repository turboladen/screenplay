class Screenplay
  module Actors
    class Directory

      # @param [Rosh::Host::RemoteDir] rosh_dir
      # @param observer The object observing the Directory.
      def initialize(rosh_dir, observer)
        @dir = rosh_dir
        @dir.add_observer(observer)
      end

      # @param [Symbol] state Designate the intended state of the directory.  If
      #   +:exists+, create it with any options given in +:options+; if
      #   +:absent+, remove it.
      # @param [Hash] options
      # @option options [String] :owner
      # @option options [String] :group
      # @option options [String] :mode
      def act(state=:exists, **options)
        owner = options[:owner]
        group = options[:group]
        mode = options[:mode]

        case state
        when :absent
          @dir.remove if @dir.exists?
        when :exists
          @dir.save unless @dir.exists?

          puts "owner: #{@dir.owner}"
          if owner && @dir.owner != owner
            @dir.owner = owner
          end

          puts "group: #{@dir.group}"
          if group && @dir.group != group
            @dir.group = group
          end

          puts "mode: #{@dir.mode}"
          if mode && @dir.mode != mode
            @dir.mode = mode
          end
        else
          raise "Unknown state: #{state}"
        end

        {
          actor: :directory,
          arguments: options.merge(state: state)
        }
      end
    end
  end
end
