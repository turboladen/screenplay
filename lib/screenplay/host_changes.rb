class Screenplay
  class HostChanges
    def initialize
      @changes = []
    end

    def update(object, attribute: attribute, old: old, new: new, as_sudo: as_sudo)
      @changes << {
        object: object,
        attribute: attribute,
        old: old,
        new: new,
        as_sudo: as_sudo
      }
    end

    def rewind
      puts 'Starting rewind...'

      @changes.reverse.each do |change|
        puts 'change', change
        obj = change[:object]
        puts "Reversing changes for object: #{obj.inspect}"

        setter_method = "#{change[:attribute]}=".to_sym
        puts "Changing via setter method: #{setter_method}"

        make_change = proc do
          obj.send(setter_method, change[:old])
          obj.save if obj.respond_to?(:save)
        end

        if change[:as_sudo]
          puts 'sudo enabled'
          change[:object].instance_variable_get(:@shell).su do
            make_change.call
          end
        else
          puts 'sudo disabled'
          make_change.call
        end
      end
    end
  end
end
