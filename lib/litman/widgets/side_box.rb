require 'gtk3'

module Widgets
  # The widget on the left containg buttons and the database chooser.
  class SideBox < Gtk::Box
    # Create a new SideBox.
    def initialize(litman)
      super(:vertical, false)

      newbib_button = ButtonWithIconAndLabel.new(Gtk::Stock::NEW, "New Bibliography")
      newbib_button.signal_connect :clicked do |button|
        new_bib = NewBibliography.new(litman, litman.main_notebook.page)
        new_bib.show_all()
        num = litman.main_notebook.append_page(new_bib)
        litman.main_notebook.page = num
      end

      update_button = ButtonWithIconAndLabel.new(Gtk::Stock::REFRESH, "Update")
      update_button.signal_connect :clicked do |button|
        message = litman.database.update()
        unless message.empty?
          litman.show_message(message[0] + " (#{message.length - 1} more)")
        end
        litman.main_notebook.get_nth_page(Litman::DOCUMENTS_PAGE).update
      end

      all_button = ButtonWithIconAndLabel.new("gtk-select-all", "All")
      all_button.signal_connect :clicked do |button|
        litman.switch_to_page(nil)
      end

      settings_button = ButtonWithIconAndLabel.new(Gtk::Stock::PREFERENCES, "Settings")
      settings_button.signal_connect :clicked do |button|
        settings = SettingsPage.new(litman, litman.main_notebook.page())
        settings.show_all()
        num = litman.main_notebook.append_page(settings)
        litman.main_notebook.page = num
      end

      self.add(newbib_button)
      self.add(update_button)
      self.add(all_button)
      self.add(litman.bibliography_chooser)
      self.pack_end(settings_button)
    end
  end
end
