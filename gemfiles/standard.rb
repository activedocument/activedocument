# frozen_string_literal: true

def standard_dependencies
  gem 'rake'

  group :development do
    gem 'yard'
  end

  group :development, :test do
    gem 'rubocop', '~> 1.63.4'
    gem 'rubocop-performance', '~> 1.21.0'
    gem 'rubocop-rails', '~> 2.24.1'
    gem 'rubocop-rake', '~> 0.6.0'
    gem 'rubocop-rspec', '~> 2.29.2'
  end

  group :test do
    gem 'rspec', '~> 3.12'
    gem 'activejob'
    gem 'timecop'
    gem 'rspec-retry'
    gem 'benchmark-ips'
    gem 'fuubar'
    gem 'rfc'
    gem 'childprocess'

    platform :mri do
      gem 'timeout-interrupt'
    end
  end

  # If platform :windows fails, please update your Bundler version
  platform :windows do
    gem 'tzinfo-data'
    gem 'wdm'
  end

  if ENV['FLE'] == 'helper'
    gem 'libmongocrypt-helper', '~> 1.8.0'
  end
end
