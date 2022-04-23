require 'gtk3'
require 'litman/database'

module Widgets

  # A list widget showing all bibliographies.
  class BibliographyChooser < Gtk::ScrolledWindow
    # Creates a new widget.
    def initialize(litman)
      @litman = litman
      @bibliography_list = Gtk::ListStore.new(String)
      rend = Gtk::CellRendererText.new()
      column = Gtk::TreeViewColumn.new("Bibliographies", rend, :text => 0)

      @tree_view = Gtk::TreeView.new(@bibliography_list)
      @tree_view.append_column(column)
      @tree_view.expand = true

      super()
      self.add(@tree_view)
      self.update()

      @tree_view.signal_connect :row_activated do |tv|
        iter = tv.selection().selected()
        litman.switch_to_page(iter[0])
      end

      @tree_view.signal_connect :button_release_event do |widget, event|
        if event.button == 3
          res = @tree_view.get_path_at_pos(event.x, event.y)
          unless res.nil?
            iter = @tree_view.selection().selected()
            menu = Menu.new(litman, iter[0])
            menu.popup_at_pointer()
          end
        end
      end
    end

    # Update the list.
    def update()
      bibs = @litman.database.bibliographies()
      @bibliography_list.clear()
      bibs.each do |db|
        @bibliography_list.append().set_values(0 => db[0])
      end
    end

    class Menu < Gtk::Menu
      def initialize(litman, item)
        super()
        bib_item = Gtk::MenuItem.new(:label => "Switch to bibliography")
        export_item = Gtk::MenuItem.new(:label => "Export bibliography")
        delete_item = Gtk::MenuItem.new(:label => "Delete bibliography")

        bib_item.signal_connect :activate do |widget, event|
          litman.switch_to_page(item)
        end

        export_item.signal_connect :activate do |widget, event|
          n = litman.switch_to_page(item)
          page = litman.main_notebook.get_nth_page(n)
          page.export()
        end

        delete_item.signal_connect :activate do |widget, event|
          page = litman.get_page(item)
          if litman.main_notebook.page == page
            litman.main_notebook.page = 0
          end
          litman.database.delete_bibliography(item)
          litman.bibliography_chooser.update()
        end

        self.add(bib_item)
        self.add(export_item)
        self.add(delete_item)
        self.show_all()
      end
    end
  end
end
