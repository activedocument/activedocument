# frozen_string_literal: true

lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require "mongoid/version"

Gem::Specification.new do |s|
  s.name        = "mongoid-ultra"
  s.version     = Mongoid::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['TableCheck Inc.', 'Durran Jordan', 'The MongoDB Ruby Team']
  s.email       = "dev@tablecheck.com"
  s.homepage    = "https://mongoid.org"
  s.summary     = "Mongoid: Ultra Edition"
  s.description = "Ruby ODM (Object Document Mapper) Framework for MongoDB. Maintained by the community, for the community."
  s.license     = "MIT"

  s.metadata = {
    'bug_tracker_uri' => 'https://github.com/tablecheck/mongoid/issues',
    'changelog_uri' => 'https://github.com/tablecheck/mongoid/releases',
    'documentation_uri' => 'https://www.mongodb.com/docs/mongoid/',
    'homepage_uri' => 'https://github.com/tablecheck/mongoid',
    'source_code_uri' => 'https://github.com/tablecheck/mongoid',
  }

  s.required_ruby_version     = ">= 2.6"
  s.required_rubygems_version = ">= 1.3.6"

  # Ruby 3.0 requires ActiveModel 6.0 or higher.
  # activemodel 7.0.0 cannot be used due to Class#descendants issue
  # See: https://github.com/rails/rails/pull/43951
  s.add_dependency("activemodel", ['>=5.1', '<7.1', '!= 7.0.0'])
  s.add_dependency("mongo", ['>=2.18.0', '<3.0.0'])
  s.add_dependency("concurrent-ruby", ['>= 1.0.5', '< 2.0'])

  # The ruby2_keywords gem is used to handling argument delegation issues.
  # It can be removed after support for Ruby 2.7 is dropped.
  s.add_dependency("ruby2_keywords", "~> 0.0.5")

  s.add_development_dependency("bson", ['>=4.14.0', '<5.0.0'])

  s.files        = Dir.glob("lib/**/*") + %w(CHANGELOG.md LICENSE README.md Rakefile)
  s.test_files   = Dir.glob("spec/**/*")
  s.require_path = 'lib'
end
