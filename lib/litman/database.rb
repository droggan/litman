require 'bibtex'
require 'sqlite3'
require 'pathname'

module Database

  ID = 0
  KEY = 1
  TITLE = 2
  AUTHORS = 3
  YEAR = 4
  FILE = 5
  DESCRIPTION = 6

  class Database

    # Creates a new Database.
    # database_file: The sqlite db file.
    # bibtex_dir: The directory containing the bibtex files.
    def initialize(database_file, bibtex_dir)
      @bibtex_dir = bibtex_dir
      @last_document_id = -1
      @last_bibliography_id = -1

      @db = SQLite3::Database.open(database_file.to_path())
      @db.execute("CREATE TABLE IF NOT EXISTS documents(id INTEGER PRIMARY KEY," +
                  "key TEXT, title TEXT, authors TEXT, year TEXT, file TEXT, " +
                  "description TEXT, UNIQUE(key, title, authors, year))")
      @db.execute("CREATE TABLE IF NOT EXISTS bibliographies(bib_name TEXT, display_name TEXT, " +
                  "description TEXT, UNIQUE(display_name))")

      res = @db.execute("SELECT name FROM sqlite_master WHERE name = 'settings'")
      if res.empty?
        @db.execute("CREATE TABLE settings(bib_dir TEXT, doc_dir TEXT, " +
                    "external_viewer INTEGER, viewer TEXT)")
        @db.execute("INSERT INTO settings VALUES(?, ?, ?, ?)",
                    "/home/dr/Documents", "/home/dr/Documents", 0, "xdg-open %s")
      end

      res = @db.execute("SELECT bib_name from bibliographies ORDER BY bib_name DESC")
      unless res.empty?
        @last_bibliography_id = res[0][0][2 .. -1].to_i
      end
    end

    # Rescans the bibtex directory and imports new files.
    # Returns: An Array of Error/Waring messages
    def update()
      entries, messages = import_dir(@bibtex_dir)
      duplicates = 0
      entries.each do |entry|
        f = entry[:file].to_s
        entry[:data].each do |e|
          k = e.key.to_s
          t = e.title.to_s
          a = e.author.to_s
          y = e.year.to_s
          @last_document_id = @last_document_id.next()
          begin
            description = "" #TODO
            @db.execute("INSERT INTO documents VALUES(?, ?, ?, ?, ?, ?, ?)",
                        @last_document_id, k, t, a, y, f, description)
          rescue Exception => e
            duplicates = duplicates + 1
          end
        end
      end
      return messages
    end

    # This helper method does the actual scannig of the bibtex directory.
    # Returns: (entry_list, messages)
    # entry_list: An Array of entries. An entry is a Hash consisting of:
    #     entry[data]: The data
    #     entry[file]; The filename (including the full path)
    # messages: An Array of Error/Waring messages
    def import_dir(dir, entry_list = [], messages = [])
      dir.each_child do |entry|
        begin
          if entry.directory?
            import_dir(entry, entry_list, messages)
          elsif entry.file?
            if entry.extname == '.bib'
              e = BibTeX.open(entry.to_s)
              entries = []
              e.each{|record| entries << record.convert(:latex)}
              entry_list << {file: entry, data: entries}
            end
          end
        rescue Exception => e
          messages.append('Error: ' + e.to_s)
        end
      end
      return entry_list, messages
    end

    # Returns an Array containing the names of the bibliographies.
    def bibliographies()
      dbs = @db.execute("SELECT display_name FROM bibliographies")
      return dbs
    end

    # Returns an Array containing information about all documents from bibliography or
    # all documents, if bibliography is nil.
    def documents(bibliography = nil)
      if bibliography.nil?
        documents = @db.query("SELECT * FROM documents")
        return documents
      else
        bib = @db.execute(
          "SELECT bib_name FROM bibliographies WHERE display_name = ?", bibliography)
        bib_name = bib[0][0]
        documents = @db.execute(
          "SELECT documents.id, key, title, authors, year, file, description FROM documents
        JOIN #{bib_name} ON documents.id = #{bib_name}.id")

        return documents
      end
    end

    # Adds a new bibliography.
    # display_name: The name of the new bibliography.
    def add_bibliography(display_name)
      bib = self.translate(display_name)
      if bib.nil?
        bib_name = "db#{@last_bibliography_id.next}"
        @last_bibliography_id = @last_bibliography_id.next
        note = ""
        @db.execute("CREATE TABLE #{bib_name} (id INTEGER, note TEXT, UNIQUE(id))")
        @db.execute("INSERT INTO bibliographies VALUES(?, ?, ?)",
                    bib_name, display_name, note)
        return :ok
      else
        return :duplicate
      end
    end

    def delete_bibliography(display_name)
      bib_name = self.translate(display_name)
      @db.execute("DROP TABLE #{bib_name}")
      @db.execute("DELETE FROM bibliographies WHERE bib_name = '#{bib_name}'")
    end

    # Adds a new document to a bibliography.
    # name: The name of the bibliography.
    # id: The id number of the document.
    def add_to_bibliography(display_name, id)
      bib_name = self.translate(display_name)
      note = ""
      @db.execute("INSERT INTO #{bib_name} VALUES(?, ?)", id, note)
    end

    # Deletes the document +id+ form the bibliography +display_name+.
    def delete_from_bibliography(display_name, id)
      bib_name = self.translate(display_name)
      @db.execute("DELETE FROM #{bib_name} WHERE id = ?", id)
    end

    # Sets the description of document +id+ to +text+.
    def set_description(id, text)
      @db.execute("UPDATE documents SET description = ? WHERE id = ?", text, id)
    end

    # Returns the note for document +id+ in bibliography +display_name+.
    def get_note(display_name, id)
      bib_name = self.translate(display_name)
      res = @db.execute("SELECT note FROM #{bib_name} WHERE id = ?", id)
      return res[0][0]
    end

    # Sets the note for +id+ in +display_name+ to +text+.
    def set_note(display_name, id, text)
      bib_name = self.translate(display_name)
      @db.execute("UPDATE #{bib_name} SET note = ? WHERE id = ?", text, id)
    end

    # Translates the display name of a bibliography into the name used internally.
    # bib_name: The name of the bibiliography.
    # returns: The internal name or nil if bib_name doesn't exist.
    def translate(bib_name)
      res = @db.execute("SELECT * FROM bibliographies WHERE display_name = ?", bib_name)
      unless res.empty?
        return res[0][0]
      end
      return nil
    end

    def bib_dir
      res = @db.execute("SELECT bib_dir FROM settings")
      return res[0][0]
    end

    def bib_dir=(value)
      @db.execute("UPDATE settings SET bib_dir = ?", value)
    end

    def doc_dir
      res = @db.execute("SELECT doc_dir FROM settings")
      return res[0][0]
    end

    def doc_dir=(value)
      @db.execute("UPDATE settings SET doc_dir = ?", value)
    end

    def viewer_command
      res = @db.execute("SELECT viewer FROM settings")
      return res[0][0]
    end

    def viewer_command=(value)
      @db.execute("UPDATE settings SET viewer = ?", value)
    end

    def external_viewer
      res = @db.execute("SELECT external_viewer FROM settings")
      if res[0].to_i == 0
        return :false
      else
        return :true
      end
    end

    def viewer_command=(value)
      if value == :true
        @db.execute("UPDATE external_viewer SET viewer = ?", 1)
      else
        @db.execute("UPDATE external_viewer SET viewer = ?", 0)
      end
    end

  end
end
