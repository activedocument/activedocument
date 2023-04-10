def standard_dependencies
  gem 'rake'

  group :development do
    gem 'yard'
  end

  group :development, :test do
    gem 'rubocop', '~> 1.49.0'
    gem 'rubocop-performance', '~> 1.16.0'
    gem 'rubocop-rails', '~> 2.17.4'
    gem 'rubocop-rake', '~> 0.6.0'
    gem 'rubocop-rspec', '~> 2.18.1'
  end

  group :test do
    gem 'rspec', '~> 3.10'
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

  if ENV['FLE'] == 'helper'
    gem 'libmongocrypt-helper', '~> 1.7.0'
  end
end
