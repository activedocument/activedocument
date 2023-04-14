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
  spec.rspec_opts = %w(--format progress)
  spec.pattern = 'spec/**/*_spec.rb'
end

$LOAD_PATH.unshift File.expand_path('lib', __dir__)
require 'mongoid/version'

task default: :spec

desc 'Generate all documentation'
task docs: 'docs:yard'

namespace :docs do
  desc 'Generate yard documention'
  task :yard do
    out = File.join('yard-docs', Mongoid::VERSION)
    FileUtils.rm_rf(out)
    system "yardoc -o #{out} --title mongoid-#{Mongoid::VERSION}"
  end
end
