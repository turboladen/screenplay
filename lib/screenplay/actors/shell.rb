class Screenplay
  module Actors
    class Shell

      # @param [Rosh::Host::Shells] shell
      def initialize(shell)
        @shell = shell
      end

      def exec(cmd)
        result = @shell.exec(cmd)

        unless @shell.last_exit_status.zero?
          raise "Command failed: #{@shell.last_result}"
        end

        result
      end

      def method_missing(meth, *args, **options, &block)
        if @shell.respond_to?(meth)
          if args.empty? && options.empty?
            @shell.send(meth, &block)
          elsif args.empty?
            @shell.send(meth, **options, &block)
          elsif options.empty?
            @shell.send(meth, *args, &block)
          else
            @shell.send(meth, *args, **options, &block)
          end
        else
          super
        end
      end
    end
  end
end
