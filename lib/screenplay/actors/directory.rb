class Screenplay
  module Actors

    # Allows for CRUDing a directory.
    #
    #
    class Directory

      # @param [Rosh::Host::RemoteDir] rosh_dir
      # @param observer The object observing the Directory.
      def initialize(rosh_dir, observer)
        @dir = rosh_dir
        @dir.add_observer(observer)
        @act_options = {}
      end

      def method_missing(meth, *args, **opts, &block)
        if @dir.respond_to?(meth)
          @act_options[meth] = {
            arguments: args,
            options: opts,
            block: block
          }

          @dir.send(meth, *args, **opts, &block)
        else
          super
        end
      end

      def act(&block)
        if block
          block.call(self)
        else
          @dir.state = :exists
        end

        {
          actor: :directory,
          arguments: @act_options
        }
      end
    end
  end
end
