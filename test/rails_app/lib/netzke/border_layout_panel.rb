module Netzke
  # It's a primitive BorderLayoutPanel, but don't let it fool you - it's a fully functionaly Netzke widget: it handles aggregatees, can be dynamically loaded, nested, etc.
  class BorderLayoutPanel < Widget::Base
    def self.js_properties
      {
        :layout => 'border'
      }
    end
  end
end