# frozen_string_literal: true

require 'bundler'
Bundler.setup

ROOT = File.expand_path(File.join(File.dirname(__FILE__)))

$LOAD_PATH << File.join(ROOT, 'spec/shared/lib')

require 'rake'
require 'rspec/core/rake_task'

# stands in for the Bundler-provided `build` task, which builds the
# gem for this project. Our release process builds the gems in a
# particular way, in a GitHub action. This task is just to help remind
# developers of that fact.
task build: :environment do
  abort <<~WARNING
    `rake build` does nothing in this project. The gem must be built via
    the `ActiveDocument Release` action on GitHub, which is triggered manually when
    a new release is ready.
  WARNING
end

# `rake version` is used by the deployment system so get the release version
# of the product beng deployed. It must do nothing more than just print the
# product version number.
#
# See the mongodb-labs/driver-github-tools/ruby/publish Github action.
desc 'Print the current value of ActiveDocument::VERSION'
task version: :environment do
  require 'active_document/version'

  puts ActiveDocument::VERSION
end

# overrides the default Bundler-provided `release` task, which also
# builds the gem. Our release process assumes the gem has already
# been built (and signed via GPG), so we just need `rake release` to
# push the gem to rubygems.
task release: :environment do
  require 'active_document/version'

  if ENV['GITHUB_ACTION'].nil?
    abort <<~WARNING
      `rake release` must be invoked from the `ActiveDocument Release` GitHub action,
      and must not be invoked locally. This ensures the gem is properly signed
      and distributed by the appropriate user.

      Note that it is the `rubygems/release-gem@v1` step in the `ActiveDocument Release`
      action that invokes this task. Do not rename or remove this task, or the
      release-gem step will fail. Reimplement this task with caution.

      mongoid-#{ActiveDocument::VERSION}.gem was NOT pushed to RubyGems.
    WARNING
  end

  system 'gem', 'push', "mongoid-#{ActiveDocument::VERSION}.gem"
end

RSpec::Core::RakeTask.new('spec') do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
end

RSpec::Core::RakeTask.new('spec:progress') do |spec|
  spec.rspec_opts = %w[--format progress]
  spec.pattern = 'spec/**/*_spec.rb'
end

desc 'Build and validate the evergreen config'
task eg: %w[eg:build eg:validate]

# 'eg' == 'evergreen', but evergreen is too many letters for convenience
namespace :eg do
  desc 'Builds the .evergreen/config.yml file from the templates'
  task build: :environment do
    ruby '.evergreen/update-evergreen-configs'
  end

  desc 'Validates the .evergreen/config.yml file'
  task validate: :environment do
    system 'evergreen validate --project mongoid .evergreen/config.yml'
  end

  desc 'Updates the evergreen executable to the latest available version'
  task update: :environment do
    system 'evergreen get-update --install'
  end

  desc 'Runs the current branch as an evergreen patch'
  task patch: :environment do
    system 'evergreen patch --uncommitted --project mongoid --browse --auto-description --yes'
  end
end

namespace :generate do
  desc 'Generates a mongoid.yml from the template'
  task config: :environment do
    require 'mongoid'
    require 'erb'

    template_path = 'lib/rails/generators/mongoid/config/templates/mongoid.yml'
    database_name = ENV['DATABASE_NAME'] || 'my_db'

    config = ERB.new(File.read(template_path), trim_mode: '-').result(binding)
    File.write('mongoid.yml', config)
  end
end

CLASSIFIERS = [
  [%r{^mongoid/attribute}, :attributes],
  [%r{^mongoid/association/[or]}, :associations_referenced],
  [%r{^mongoid/association}, :associations],
  [/^mongoid/, :unit],
  [/^integration/, :integration],
  [/^rails/, :rails]
].freeze

RUN_PRIORITY = %i[
  unit attributes associations_referenced associations
  integration rails
].freeze

def spec_organizer
  require 'mrss/spec_organizer'

  Mrss::SpecOrganizer.new(
    root: ROOT,
    classifiers: CLASSIFIERS,
    priority_order: RUN_PRIORITY
  )
end

task ci: :environment do
  spec_organizer.run
end

task :bucket, %i[buckets] => :environment do |_task, args|
  buckets = args[:buckets]
  buckets = if buckets.blank?
              [nil]
            else
              buckets.split(':').map do |bucket|
                if bucket.empty?
                  nil
                else
                  bucket.to_sym
                end
              end
            end
  spec_organizer.run_buckets(*buckets)
end

task default: :spec

desc 'Generate all documentation'
task docs: 'docs:yard'

namespace :docs do
  desc 'Generate yard documentation'
  task yard: :environment do
    require 'active_document/version'

    out = File.join('yard-docs', ActiveDocument::VERSION)
    FileUtils.rm_rf(out)
    system "yardoc -o #{out} --title mongoid-#{ActiveDocument::VERSION}"
  end
end
