# frozen_string_literal: true

require 'bundler'
require 'bundler/gem_tasks'
Bundler.setup

require 'rake'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new('spec') do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
end

RSpec::Core::RakeTask.new('spec:progress') do |spec|
  spec.rspec_opts = %w[--format progress]
  spec.pattern = 'spec/**/*_spec.rb'
end

namespace :generate do
  desc 'Generates active_document.yml from the template'
  task config: :environment do
    require 'active_document'
    require 'erb'

    template_path = 'lib/rails/generators/active_document/config/templates/active_document.yml'
    config = ERB.new(File.read(template_path), trim_mode: '-').result(binding)
    File.write('active_document.yml', config)
  end
end

$LOAD_PATH.unshift File.expand_path('lib', __dir__)
require 'active_document/version'

task default: :spec

desc 'Generate all documentation'
task docs: %i[docs:yard docs:sphinx]

namespace :docs do
  desc 'Generate YARD documentation'
  task :yard do # rubocop:disable Rails/RakeEnvironment
    out = File.join('yard-docs', ActiveDocument::VERSION)
    FileUtils.rm_rf(out)
    system "yardoc -o #{out} --title active_document-#{ActiveDocument::VERSION}"
  end

  desc 'Generate Sphinx documentation'
  task :sphinx do # rubocop:disable Rails/RakeEnvironment
    # TODO: generate sphinx docs
  end
end

# Rakefile
require 'simplecov'

namespace :simplecov do
  desc 'Generate coverage report'
  task :report do # rubocop:disable Rails/RakeEnvironment
    SimpleCov.start
    Rake::Task['spec'].invoke
    coverage_result = SimpleCov.result.format!
    puts "Coverage Report: #{coverage_result.covered_percent.round(2)}%"
  end
end
