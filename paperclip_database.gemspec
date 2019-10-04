# -*- ruby -*-

$LOAD_PATH.push File.expand_path("../lib", __FILE__)
require 'paperclip_database/version'

Gem::Specification.new do |s|
  s.name              = "paperclip_database"
  s.version           = PaperclipDatabase::VERSION
  s.platform          = Gem::Platform::RUBY
  s.author            = "Jarl Friis"
  s.email             = ["jarl@softace.dk"]
  s.homepage          = "https://github.com/softace/paperclip_database"
  s.summary           = "Database storage for paperclip"
  s.description       = "To have all your data in one place: the database"
  s.license           = 'MIT'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.requirements << "ImageMagick"

  s.add_dependency('paperclip', '>= 2.3.0')

  s.add_development_dependency('rspec', '~> 3.1')
  s.add_development_dependency('appraisal', '~> 2.0')
#  s.add_development_dependency('rails', '>= 3.0.0') # Appraisal
  s.add_development_dependency('sqlite3', '~> 1.3.0')
  s.add_development_dependency('cucumber', '~> 1.1')
  s.add_development_dependency('launchy', '~> 2.1')
  s.add_development_dependency('aruba')
  s.add_development_dependency('capybara', '~> 2.0.0', '< 2.1.0')
  s.add_development_dependency('bundler', '< 2.0')
  s.add_development_dependency('rake')
  s.add_development_dependency('fakeweb')
end
