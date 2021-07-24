require 'gtk3'

module Widgets

  class MessageBar < Gtk::InfoBar
    def initialize()
      super()
      @label = Gtk::Label.new()
      icon = Gtk::Image.new(:icon_name => "close", :size => Gtk::IconSize::MENU)
      close_button = Gtk::Button.new()
      close_button.add(icon)
      close_button.signal_connect :clicked do |w, ev|
        self.hide()
      end
      self.content_area.add(@label)
      self.action_area.add(close_button)
    end

    def show_message(message)
      @label.text = message
      self.show()
    end
  end
end
