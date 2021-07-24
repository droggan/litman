require 'gtk3'

module Widgets

  class SettingsPage < Gtk::Box

    def initialize(litman, previous_page)
      super(:vertical)

      grid = Gtk::Grid.new()
      grid.vexpand = true

      bib_dir_label = Gtk::Label.new("Bibtex directory:")
      bib_dir_entry = Gtk::Entry.new()
      bib_dir_entry.hexpand = true
      bib_dir_entry.text = litman.database.bib_dir
      bib_dir_entry.signal_connect :changed do |entry|
        litman.database.bib_dir = bib_dir_entry.text
      end

      documents_label = Gtk::Label.new("Documents entry:")
      documents_entry = Gtk::Entry.new()
      documents_entry.hexpand = true
      documents_entry.text = litman.database.doc_dir
      documents_entry.signal_connect :changed do |entry|
        litman.database.doc_dir = documents_entry.text
      end

      viewer_label = Gtk::Label.new("Viewer Command:")
      viewer_entry = Gtk::Entry.new()
      viewer_entry.hexpand = true
      viewer_entry.text = litman.database.viewer_command
      viewer_entry.signal_connect :changed do |entry|
        litman.database.viewer_command = viewer_entry.text
      end

      close_button = ButtonWithIconAndLabel.new("close", "Close")
      close_button.hexpand = true
      close_button.signal_connect :clicked do |w, ev|
        id = litman.main_notebook.page_num(self)
        litman.main_notebook.remove_page(id)
        litman.main_notebook.page = previous_page
      end

      grid.attach(bib_dir_label, 0, 0, 1, 1)
      grid.attach(bib_dir_entry, 1, 0, 2, 1)
      grid.attach(documents_label, 0, 1, 1, 1)
      grid.attach(documents_entry, 1, 1, 2, 1)
      grid.attach(viewer_label, 0, 2, 1, 1)
      grid.attach(viewer_entry, 1, 2, 2, 1)

      self.add(grid)
      self.add(close_button)

    end
  end
end
