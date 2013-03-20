require 'log_switch'

class Screenplay
  extend LogSwitch
  include LogSwitch::Mixin
end

Screenplay.log_class_name = true
