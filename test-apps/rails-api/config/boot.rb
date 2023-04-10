ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

require 'bundler/setup' # Set up gems listed in the Gemfile.

# bootsnap causes weird errors on Ruby 3 as of end of 2021.
#require 'bootsnap/setup' # Speed up boot time by caching expensive operations.
