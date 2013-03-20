Dir[File.dirname(__FILE__) + '/actions/*.rb'].each(&method(:require))


class Screenplay
  # Actions provides methods to all types of classes included in the
  # Screenplay::Actions module.  It defines a method based on the class name.
  # Include this into any class to gain access to the commands.
  module Actions
    Screenplay::Actions.constants.each do |action_class|
      define_method(action_class.to_s.downcase.to_sym) do |**options, &block|
        klass = Screenplay::Actions.const_get(action_class)
        @actions << klass.new(**options, &block)
      end
    end
  end
end
