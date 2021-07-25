module Widgets

  class Exporter < Gtk::Box
    def initialize(viewer, list_of_filenames)
      super(:vertical)

      sw = Gtk::ScrolledWindow.new()
      text_view = Gtk::TextView.new()
      text_view.monospace = true
      text_view.hexpand = true
      text_view.vexpand = true
      sw.add(text_view)
      sw.show_all()

      list_of_filenames.each do |file|
        begin
          f = File.open(file)
          text = f.read()
          iter = text_view.buffer.get_iter_at(:line => 0)
          text_view.buffer.insert(iter, text)
        rescue
          @litman.show_message("Can't open file #{file}")
        end
      end

      close_button = ButtonWithIconAndLabel.new("close", "Close")
      close_button.hexpand = true
      save_button = ButtonWithIconAndLabel.new("document-save", "Save")
      save_button.hexpand = true
      button_box = Gtk::Box.new(:horizontal)
      button_box.hexpand = true
      button_box.add(close_button)
      button_box.add(save_button)

      self.add(sw)
      self.add(button_box)
      self.show_all

      viewer.append_page(self)
      page = viewer.page_num(self)
      viewer.page = page

      close_button.signal_connect :clicked do |w, e|
        id = viewer.page_num(self)
        viewer.remove_page(id)
      end

      save_button.signal_connect :clicked do |w, e|
        dialog = Gtk::FileChooserDialog.new(
          :title => "Save As",
          :parent => nil,
          :action => :save,
          :buttons => [["Save", Gtk::ResponseType::ACCEPT],
                       ["Cancel", Gtk::ResponseType::CANCEL]])
        dialog.create_folders = true
        dialog.do_overwrite_confirmation = true
        file = nil
        res = dialog.run()
        if res == Gtk::ResponseType::ACCEPT
          file = dialog.filename()
        end
        dialog.destroy()
        unless file.nil?
          p = Pathname.new(file)
          begin
            p.write(text_view.buffer.text())
          rescue
            @litman.show_message("Cannot write #{p}")
          end
        end
      end

    end
  end
end
