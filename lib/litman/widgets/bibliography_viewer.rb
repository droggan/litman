require 'gtk3'
require 'litman/database'
require 'pathname'

module Widgets

  # A list widget showing all documents in a bibliography.
  class BibliographyViewer < Gtk::Notebook

    # Creates a new widgets showing documents from +bibliography_name+.
    def initialize(litman, bibliography_name = nil)
      @litman = litman
      @bibliography_name = bibliography_name

      super()
      self.show_tabs = false
      @bibliography_store = Gtk::ListStore.new(String, String, String, String,
                                               String, String, String, String)
      filter = @bibliography_store.create_filter()

      @tree_view = Gtk::TreeView.new(filter)

      sw = Gtk::ScrolledWindow.new()
      sw.hexpand = true
      sw.vexpand = true
      sw.add(@tree_view)

      filter_box = Gtk::Box.new(:horizontal, 5)

      filter_entry = Gtk::Entry.new()
      filter_entry.hexpand = true
      filter_entry.signal_connect :changed do |w, e|
        filter.refilter()
      end

      filter_label = Gtk::Label.new("Filter:")
      filter_box.add(filter_label)
      filter_box.add(filter_entry)

      filter.set_visible_func do |model, iter|
        if iter[4].nil?
          true
        else
          text = filter_entry.text()
          while text.sub!(" ", ".*")
            nil
          end
          text = ".*" + text + ".*"
          re = Regexp.new(text, true)
          if iter[1].match?(re) or iter[2].match?(re) or
            iter[3].match?(re) or iter[4].match?(re)
            true
          else
            false
          end
        end
      end

      box = Gtk::Box.new(:vertical)
      box.add(sw)
      box.add(filter_box)

      if bibliography_name != nil
        self.append_page(box, Gtk::Label.new(bibliography_name))
      else
        self.append_page(box, Gtk::Label.new("All"))
      end
      ["Key", "Title", "Author", "Year"].each_with_index do |title, i|
        r = Gtk::CellRendererText.new()
        c = Gtk::TreeViewColumn.new(title, r, :text => i + 1)
        c.sort_column_id = i + 1
        @tree_view.append_column(c)
      end
      @tree_view.headers_clickable = true
      @tree_view.rubber_banding = true
      selection = @tree_view.selection()
      selection.mode = :multiple

      @tree_view.columns.each do |c|
        c.resizable = true
      end

      @tree_view.signal_connect :row_activated do |bv|
        self.info()
      end

      @tree_view.signal_connect :button_release_event do |widget, event|
        if event.button == 3
          res = @tree_view.get_path_at_pos(event.x, event.y)
          unless res.nil?
            menu = Menu.new(litman, self, selection, bibliography_name)
            menu.popup_at_pointer()
          end
        end
      end

      self.update()
    end

    # Update the list. Call this when the bibliography changed.
    def update()
      @bibliography_store.clear()
      documents = @litman.database.documents(@bibliography_name)
      documents.each do |doc|
        new_row = @bibliography_store.append()
        doc.each_with_index do |v, i|
          new_row.set_values(i => v.to_s)
        end
      end
    end

    # Show the DocumentInfo page.
    def info()
      DocumentInfoPage.new(@litman, self, @bibliography_name, @tree_view.selection)
    end

    # Export the bibliography or selection.
    def export()
      files = []
      data = @tree_view.model
      if @tree_view.selection.count_selected_rows != 0
        data = @tree_view.selection
      end
      data.each do |model, path, iter|
        files << iter[Database::FILE]
      end
      self.export_files(files)
    end

    # Export the files given by +files+
    def export_files(files)
      Exporter.new(self, files)
    end
  end

  class Menu < Gtk::Menu
    def initialize(litman, viewer, selection, bib_name)
      super()

      info_item = Gtk::MenuItem.new(:label => "Info")
      open_item = Gtk::MenuItem.new(:label => "Open")
      export_item = Gtk::MenuItem.new(:label => "Export")
      delete_item = Gtk::MenuItem.new(:label => "Delete")
      add_item = Gtk::MenuItem.new(:label => "Add to")
      add_item.set_submenu(SubMenu.new(litman, selection, bib_name))

      info_item.signal_connect :activate do |w, ev|
        viewer.info()
      end

      open_item.signal_connect :activate do |w, ev|
        selection.each do |model, path, iter|
          litman.open(iter[Database::KEY], iter[Database::FILE])
        end
      end

      export_item.signal_connect :activate do |w, ev|
        viewer.export()
      end

      delete_item.signal_connect :activate do |w, ev|
        selection.each do |model, path, iter|
          litman.database.delete_from_bibliography(bib_name, iter[0])
        end
        viewer.update()
      end

      self.add(info_item)
      self.add(open_item)
      self.add(export_item)
      unless bib_name.nil?
        self.add(delete_item)
      end
      self.add(add_item)
      self.show_all()
    end
  end

  class SubMenu < Gtk::Menu
    def initialize(litman, selection, bib_name)
      super()
      top = Gtk::MenuItem.new(:label => "New bibliography")
      top.signal_connect :activate do |w, ev|
        new_bib = NewBibliography.new(litman, litman.main_notebook.page, selection)
        new_bib.show_all()
        num = litman.main_notebook.append_page(new_bib)
        litman.main_notebook.page = num
      end
      self.add(top)
      self.add(Gtk::SeparatorMenuItem.new())
      dbs = litman.database.bibliographies()
      dbs.each do |db|
        item = Gtk::MenuItem.new(:label => db[0])
        item.signal_connect :activate do |w, ev|
          selection.each do |model, path, iter|
            litman.database.add_to_bibliography(db[0], iter[0])
          end
          page = litman.get_page(db[0])
          page.update()
        end
        self.add(item)
      end
    end
  end
end
