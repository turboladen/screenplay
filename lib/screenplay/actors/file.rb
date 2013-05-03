require 'log_switch'


class Screenplay
  module Actors
    class File
      extend LogSwitch
      include LogSwitch::Mixin

      def initialize(rosh_file, observer)
        @file = rosh_file
        @file.add_observer(observer)
      end

      def act(state: :exists, **options)
        owner = options[:owner] if options[:owner]
        group = options[:group] if options[:group]
        mode = options[:mode] if options[:mode]
        contents = options[:contents] if options[:contents]

        case state
        when :absent
          @file.remove
        when :exists
          if contents
            exists_with_content(contents)
          else
            @file.exists?
          end

          log "owner: #{@file.owner}"
          if owner && @file.owner != owner
            @file.owner = owner
          end

          log "group: #{@file.group}"
          if group && @file.group != group
            @file.group = group
          end

          log "mode: #{@file.mode}"
          if mode && @file.mode != mode
            @file.mode = mode
          end
        else
          raise "Unknown state: #{state}"
        end

        {
          actor: :file,
          arguments: options.merge(state: state)
        }
      end

      def remove
        @file.remove if @file.exists?
      end

      def exists
        @file.exists?
      end

      def exists_with_content(contents)
        tmp_contents = extract_contents(contents)

        log "tmp_contents: #{tmp_contents}"
        log "tmp_contents size: #{tmp_contents.size}"

        if @file.exists?
          log 'File exists'
          log "file contents size: #{@file.contents.size}"

          unless @file.contents == tmp_contents
            log 'File contents differ'

            @file.contents = tmp_contents
            @file.save
          end
        else
          log 'File does not exist'
          @file.contents = tmp_contents

          @file.save
        end
      end

      def method_missing(meth, *args, **options, &block)
        if @file.respond_to?(meth)
          if args.empty? && options.empty?
            @file.send(meth, &block)
          elsif args.empty?
            @file.send(meth, **options, &block)
          elsif options.empty?
            @file.send(meth, *args, &block)
          else
            @file.send(meth, *args, **options, &block)
          end
        else
          super
        end
      end

      private

      def extract_contents(contents)
        if contents.kind_of? Proc
          contents.call(@file)
        elsif contents.kind_of? File
          File.read(contents)
        else
          contents
        end
      end
    end
  end
end
