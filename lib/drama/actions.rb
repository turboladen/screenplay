Dir[File.dirname(__FILE__) + '/actions/*.rb'].each(&method(:require))


class Drama
  # Actions provides methods to all types of classes included in the
  # Drama::Actions module.  It defines a method based on the class name.
  # Include this into any class to gain access to the commands.
  module Actions
    Drama::Actions.constants.each do |action_class|
      define_method action_class do |**options|
        klass = Drama::Actions.const_get(action_class)
        @actions << klass.new(**options)
      end
    end
  end
end
