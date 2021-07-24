require 'gtk3'
require 'litman/database'
require 'pathname'

module Widgets
  # This widget shows data belonging to specific document.
  class DocumentInfo < Gtk::Frame
    def initialize(litman, viewer, bib_name, iter)

      frame_box = Gtk::Box.new(:horizontal, 5)
      frame_label = Gtk::Label.new(iter[Database::KEY])
      open_button = Gtk::Button.new(:icon_name => "document-open")
      open_button.signal_connect :clicked do |w, ev|
        key = iter[Database::KEY]
        file = iter[Database::FILE]
        litman.open(key, file)
      end
      export_button = Gtk::Button.new(:icon_name => "document-export")
      export_button.signal_connect :clicked do |w, ev|
        viewer.export_files([iter[Database::FILE]])
      end
      frame_box.add(frame_label)
      frame_box.add(open_button)
      frame_box.add(export_button)

      super()
      self.label_widget = frame_box
      info_box = Gtk::Box.new(:vertical, 5)

      title = Gtk::Label.new(iter[Database::TITLE] + " (#{iter[Database::YEAR]})")
      authors = Gtk::Label.new(iter[Database::AUTHORS])
      header_box = Gtk::Box.new(:vertical, 5)
      header_box.add(title)
      header_box.add(authors)

      description_label = Gtk::Label.new("Description:")
      description_entry = Gtk::TextView.new()
      description_entry.hexpand = true
      description_entry.buffer.text = iter[Database::DESCRIPTION]
      description_entry.buffer.signal_connect :changed do |w, ev|
        litman.database.set_description(iter[Database::ID], w.text)
      end
      description_box = Gtk::Box.new(:horizontal)
      description_box.pack_start(description_label)
      description_sw = Gtk::ScrolledWindow.new()
      description_sw.add(description_entry)

      info_box.add(header_box)

      grid = Gtk::Grid.new()
      grid.row_spacing = 5
      grid.column_spacing = 5
      grid.row_homogeneous = true
      grid.column_homogeneous = true
      grid.attach(description_box, 0, 0, 1, 1)
      grid.attach(description_sw, 0, 1, 5, 5)
      unless bib_name.nil?
        note_label = Gtk::Label.new("Note:")
        note_entry = Gtk::TextView.new()
        note_entry.hexpand = true
        res = litman.database.get_note(bib_name, iter[Database::ID])
        note_entry.buffer.text = res
        note_entry.buffer.signal_connect :changed do |w, ev|
          litman.database.set_note(bib_name, iter[Database::ID], note_entry.buffer.text)
        end
        note_box = Gtk::Box.new(:horizontal)
        note_box.pack_start(note_label)
        note_sw = Gtk::ScrolledWindow.new()
        note_sw.add(note_entry)
        grid.attach(note_box, 5, 0, 1, 1)
        grid.attach(note_sw, 5, 1, 5, 5)
      end
      info_box.add(grid)
      self.add(info_box)
    end
  end
end