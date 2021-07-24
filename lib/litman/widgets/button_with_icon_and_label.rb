require 'gtk3'

module Widgets

  # A Button with an icon on the left and a label on the right.
  class ButtonWithIconAndLabel < Gtk::Button
    # Creates a new button with icon +icon_name+ and text +text+.
    # If +center+ is true, the icon and text will be centered.
    def initialize(icon_name, text, center = false)
      super()
      button_box = Gtk::Box.new(:horizontal, 5)
      icon = Gtk::Image.new(:icon_name => icon_name, :size => Gtk::IconSize::BUTTON)
      label = Gtk::Label.new(text)
      button_box.add(icon)
      button_box.add(label)

      if center
        center_box = Gtk::Box.new(:horizontal)
        center_box.center_widget = button_box
        self.add(center_box)
      else
        self.add(button_box)
      end
    end
  end

end
