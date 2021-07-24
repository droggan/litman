require 'gtk3'

module Widgets

  # A widget used to create a new bibliography.
  class NewBibliography < Gtk::Box
    attr_accessor :previous_page, :model

    # Creates a new widget.
    def initialize(litman, previous_page, selected_rows = nil)
      @litman = litman
      super(:vertical)
      @previous_page = previous_page

      @entry = Gtk::Entry.new()
      @entry.text = "New Bibliography"

      @model = Gtk::ListStore.new(String, String, String, String,
                                  String, String, String, String)
      @tree_view = Gtk::TreeView.new(@model)
      ["Key", "Title", "Author", "Year"].each_with_index do |title, i|
        r = Gtk::CellRendererText.new()
        c = Gtk::TreeViewColumn.new(title, r, :text => i + 1)
        c.sort_column_id = i + 1
        @tree_view.append_column(c)
      end
      @tree_view.headers_clickable = true
      @tree_view.rubber_banding = true
      @tree_view.expand = true
      selection = @tree_view.selection()
      selection.mode = :multiple
      @tree_view.columns.each do |c|
        c.resizable = true
      end
      sw = Gtk::ScrolledWindow.new()
      sw.add(@tree_view)

      if selected_rows.nil?
        docs = litman.database.documents()
        docs.each do |doc|
          new_row = @model.append()
          doc.each_with_index do |v, i|
            new_row.set_values(i => v.to_s)
          end
        end
      else
        selected_rows.each do |model, path, iter|
          new_row = @model.append()
          8.times do |n|
            new_row.set_values(n => iter[n].to_s)
          end
        end
        @tree_view.selection.select_all()
      end

      ok_button = ButtonWithIconAndLabel.new(Gtk::Stock::OK, "OK", true)
      ok_button.signal_connect :clicked do |button|
        # get dbname
        name = @entry.text()
        # make new db
        res = litman.database.add_bibliography(name)
        if res == :duplicate
          litman.show_message("Bibliography #{name} already exists.")
        else
          @tree_view.selection.each do |store, row, iter|
            litman.database.add_to_bibliography(name, iter[0])
          end
          litman.bibliography_chooser.update()
          litman.add_bibliography_viewer(name)
        end
      end
      cancel_button = ButtonWithIconAndLabel.new(Gtk::Stock::CANCEL, "Cancel", true)
      cancel_button.signal_connect :clicked do |button|
        litman.main_notebook.page = @previous_page
        id = litman.main_notebook.page_num(self)
        litman.main_notebook.remove_page(id)
      end
      button_box = Gtk::Box.new(:horizontal)
      button_box.hexpand = true
      button_box.pack_start(cancel_button, :expand => true, :fill => true)
      button_box.pack_start(ok_button, :expand => true, :fill => true)

      button_bar = Gtk::Box.new(:horizontal)
      button_bar.pack_start(button_box, :expand => true, :fill => true)

      self.hexpand = true
      self.add(@entry)
      self.add(sw)
      self.pack_end(button_bar)
    end

    # Marks the text, so it can be changend by typing.
    def select_text()
      @entry.select_region(0, -1)
      @entry.grab_focus()
    end
  end
end
