# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'active_document/version'

Gem::Specification.new do |s|
  s.name        = ActiveDocument::GEM_NAME
  s.version     = ActiveDocument::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Johnny Shields']
  s.email       = 'johnny.shields@gmail.com'
  s.homepage    = 'https://github.com/activedocument/activedocument'
  s.summary     = 'ActiveDocument is a Ruby ODM (Object Document Mapper) framework for No-SQL databases.'
  s.description = 'Ruby ODM (Object Document Mapper) framework for No-SQL databases.'
  s.license     = 'MIT'

  s.metadata = {
    'rubygems_mfa_required' => 'true',
    'bug_tracker_uri' => 'https://github.com/activedocument/activedocument/issues',
    'changelog_uri' => 'https://github.com/activedocument/activedocument/releases',
    'documentation_uri' => 'https://www.mongodb.com/docs/active_document/',
    'homepage_uri' => 'https://github.com/activedocument/activedocument',
    'source_code_uri' => 'https://github.com/activedocument/activedocument'
  }

  s.required_ruby_version = '>= 3.1'

  # activemodel 7.0.0 cannot be used due to Class#descendants issue
  # See: https://github.com/rails/rails/pull/43951
  s.add_dependency('activemodel', ['>=6.1', '!= 7.0.0'])
  s.add_dependency('mongo', ['>=2.18.0'])
  s.add_dependency('concurrent-ruby', ['>= 1.0.5'])

  s.files = Dir.glob('lib/**/*') + %w[LICENSE README.md Rakefile]
  s.require_path = 'lib'
end
