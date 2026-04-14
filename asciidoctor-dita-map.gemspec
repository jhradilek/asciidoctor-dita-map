require_relative 'lib/dita-map/version'

Gem::Specification.new do |s|
  # General information:
  s.name        = 'asciidoctor-dita-map'
  s.version     = AsciidoctorDitaMap::VERSION
  s.summary     = 'Convert an AsciiDoc file to a DITA map'
  s.description = 'A command line utility that converts a single AsciiDoc file to a DITA map.'
  s.authors     = ['Jaromir Hradilek']
  s.email       = 'jhradilek@gmail.com'
  s.bindir      = 'bin'
  s.executables = ['dita-map']
  s.files       = [
    'lib/dita-map/version.rb',
    'lib/dita-map/cli.rb',
    'LICENSE',
    'AUTHORS',
    'README.md'
  ]
  s.homepage    = 'https://github.com/jhradilek/asciidoctor-dita-map'
  s.license     = 'MIT'

  # Relevant metadata:
  s.metadata = {
    'homepage_uri'      => 'https://github.com/jhradilek/asciidoctor-dita-map',
    'bug_tracker_uri'   => 'https://github.com/jhradilek/asciidoctor-dita-map/issues',
    'documentation_uri' => 'https://github.com/jhradilek/asciidoctor-dita-map/blob/main/README.md'
  }

  # Minimum required Ruby version:
  s.required_ruby_version = '>= 3.2'

  # Required gems:
  s.add_runtime_dependency 'asciidoctor', '~> 2.0', '>= 2.0.26'
  s.add_runtime_dependency 'rexml', '~> 3.4', '>= 3.4.4'

  # Development gems:
  s.add_development_dependency 'rake', '~> 13.3', '>= 13.3.1'
  s.add_development_dependency 'minitest', '~> 6.0', '>= 6.0.2'
  s.add_development_dependency 'minitest-mock', '~> 5.27'
end
