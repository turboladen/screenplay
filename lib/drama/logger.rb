require 'log_switch'

class Drama
  extend LogSwitch
  include LogSwitch::Mixin
end

Drama.log_class_name = true
