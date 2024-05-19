# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'active_document/version'

Gem::Specification.new do |s|
  s.name        = ActiveDocument::GEM_NAME
  s.version     = ActiveDocument::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['TableCheck Inc.', 'Durran Jordan', 'The MongoDB Ruby Team']
  s.email       = 'dev@tablecheck.com'
  s.homepage    = 'https://active_document.org'
  s.summary     = 'ActiveDocument: Ultra Edition'
  s.description = 'Ruby ODM (Object Document Mapper) Framework for MongoDB. Maintained by the community, for the community.'
  s.license     = 'MIT'

  s.metadata = {
    'rubygems_mfa_required' => 'true',
    'bug_tracker_uri' => 'https://github.com/tablecheck/active_document/issues',
    'changelog_uri' => 'https://github.com/tablecheck/active_document/releases',
    'documentation_uri' => 'https://www.mongodb.com/docs/active_document/',
    'homepage_uri' => 'https://github.com/tablecheck/active_document',
    'source_code_uri' => 'https://github.com/tablecheck/active_document'
  }

  s.required_ruby_version = '>= 2.7'
  s.required_rubygems_version = '>= 1.3.6'

  # activemodel 7.0.0 cannot be used due to Class#descendants issue
  # See: https://github.com/rails/rails/pull/43951
  s.add_dependency('activemodel', ['>=5.1', '<7.2', '!= 7.0.0'])
  s.add_dependency('mongo', ['>=2.18.0', '<3.0.0'])
  s.add_dependency('concurrent-ruby', ['>= 1.0.5', '< 2.0'])

  s.add_development_dependency('bson', ['>= 4.14.0', '< 6.0.0'])

  s.files        = Dir.glob('lib/**/*') + %w[LICENSE README.md Rakefile]
  s.require_path = 'lib'
end
