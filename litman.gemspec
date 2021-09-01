Gem::Specification.new do |s|
  s.name = "litman"
  s.version = "0.0.2"
  s.license = "0BSD"
  s.summary = "A reference manager"
  s.authors = ["Dennis Roggan"]
  s.files = Dir["lib/litman/*", "lib/litman/widgets/*"]
  s.executables = ["litman"]
  s.add_runtime_dependency("gtk3")
  s.add_runtime_dependency("bibtex-ruby")
  s.add_runtime_dependency("sqlite3")
end
