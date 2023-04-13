# frozen_string_literal: true

require 'i18n'

# rubocop:disable RSpec/BeforeAfterAll
module Constraints
  RAILS_VERSION = ActiveSupport.version.to_s.split('.')[0..1].join('.').freeze

  # This is a macro for retrying flaky tests on CI that occasionally fail.
  # Note that the tests will only be retried on CI.
  #
  # @param [ Integer ] :tries The number of times to retry.
  # @param [ Integer ] :sleep The number of seconds to sleep in between retries.
  #   If nothing, or nil, is passed, we won't wait in between retries.
  def retry_test(tries: 3, sleep: nil)
    if %w(1 yes true).include?(ENV['CI'])
      around do |example|
        if sleep
          example.run_with_retry retry: tries, retry_wait: sleep
        else
          example.run_with_retry retry: tries
        end
      end
    end
  end

  class I18nBackendWithFallbacks < ::I18n::Backend::Simple
    include ::I18n::Backend::Fallbacks
  end

  def with_i18n_fallbacks
    around do |example|
      old_backend = ::I18n.backend
      ::I18n.backend = I18nBackendWithFallbacks.new
      example.run
    ensure
      ::I18n.backend = old_backend
    end
  end

  def without_i18n_fallbacks
    around do |example|
      old_backend = ::I18n.backend
      ::I18n.backend = ::I18n::Backend::Simple.new
      example.run
    ensure
      ::I18n.backend = old_backend
    end
  end

  def require_mri
    before(:all) do
      unless SpecConfig.instance.mri?
        skip "MRI required, we have #{SpecConfig.instance.platform}"
      end
    end
  end

  def min_driver_version(version)
    required_version = version.split('.').map(&:to_i)
    actual_version = driver_version(required_version.length)
    before(:all) do
      if (actual_version <=> required_version) < 0
        skip "Driver version #{version} or higher is required"
      end
    end
  end

  def max_driver_version(version)
    required_version = version.split('.').map(&:to_i)
    actual_version = driver_version(required_version.length)
    before(:all) do
      if (actual_version <=> required_version) > 0
        skip "Driver version #{version} or lower is required"
      end
    end
  end

  def driver_version(precision)
    Mongo::VERSION.split('.')[0...precision].map(&:to_i)
  end

  def min_bson_version(version)
    required_version = version.split('.').map(&:to_i)
    actual_version = bson_version(required_version.length)
    before(:all) do
      if (actual_version <=> required_version) < 0
        skip "bson-ruby version #{version} or higher is required"
      end
    end
  end

  def max_bson_version(version)
    required_version = version.split('.').map(&:to_i)
    actual_version = bson_version(required_version.length)
    before(:all) do
      if (actual_version <=> required_version) > 0
        skip "bson-ruby version #{version} or lower is required"
      end
    end
  end

  def bson_version(precision)
    BSON::VERSION.split('.')[0...precision].map(&:to_i)
  end

  def min_ruby_version(version)
    before(:all) do
      if version > RUBY_VERSION
        skip "Ruby version #{version} or higher required, we have #{RUBY_VERSION}"
      end
    end
  end

  def max_ruby_version(version)
    before(:all) do
      if version < RUBY_VERSION
        skip "Ruby version #{version} or higher required, we have #{RUBY_VERSION}"
      end
    end
  end

  def min_rails_version(version)
    unless version =~ /\A\d+\.\d+\z/
      raise ArgumentError, "Version can only be major.minor: #{version}"
    end

    before(:all) do
      if version > RAILS_VERSION
        skip "Rails version #{version} or higher required, we have #{RAILS_VERSION}"
      end
    end
  end

  def max_rails_version(version)
    unless version =~ /\A\d+\.\d+\z/
      raise ArgumentError, "Version can only be major.minor: #{version}"
    end

    before(:all) do
      if version < RAILS_VERSION
        skip "Rails version #{version} or lower required, we have #{RAILS_VERSION}"
      end
    end
  end

  def min_server_version(version)
    parsed_version = Gem::Version.new(version)

    before(:all) do
      if parsed_version > Gem::Version.new(ClusterConfig.instance.server_version)
        skip "Server version #{version} or higher required, we have #{ClusterConfig.instance.server_version}"
      end
    end
  end

  def max_server_version(version)
    parsed_version = Gem::Version.new(version)

    before(:all) do
      if parsed_version < Gem::Version.new(ClusterConfig.instance.server_version)
        skip "Server version #{version} or lower required, we have #{ClusterConfig.instance.server_version}"
      end
    end
  end

  def min_server_fcv(version)
    parsed_version = Gem::Version.new(version)

    before(:all) do
      unless Gem::Version.new(ClusterConfig.instance.fcv_ish) >= parsed_version
        skip "FCV #{version} or higher required, we have #{ClusterConfig.instance.fcv_ish} (server #{ClusterConfig.instance.server_version})"
      end
    end
  end

  def max_server_fcv(version)
    parsed_version = Gem::Version.new(version)

    before(:all) do
      if parsed_version < Gem::Version.new(ClusterConfig.instance.fcv_ish)
        skip "FCV #{version} or lower required, we have #{ClusterConfig.instance.fcv_ish} (server #{ClusterConfig.instance.server_version})"
      end
    end
  end

  def require_topology(*topologies)
    invalid_topologies = topologies - [:single, :replica_set, :sharded, :load_balanced]

    unless invalid_topologies.empty?
      raise ArgumentError, "Invalid topologies requested: #{invalid_topologies.join(', ')}"
    end

    before(:all) do
      unless topologies.include?(topology = ClusterConfig.instance.topology)
        skip "Topology #{topologies.join(' or ')} required, we have #{topology}"
      end
    end
  end

  def require_transaction_support
    before(:all) do
      case ClusterConfig.instance.topology
      when :single
        skip 'Transactions tests require a replica set (4.0+) or a sharded cluster (4.2+)'
      when :replica_set
        unless ClusterConfig.instance.server_version >= '4.0'
          skip 'Transactions tests in a replica set topology require server 4.0+'
        end
      when :sharded, :load_balanced
        unless ClusterConfig.instance.server_version >= '4.2'
          skip 'Transactions tests in a sharded cluster topology require server 4.2+'
        end
      else
        raise NotImplementedError
      end
    end
  end

  def require_multi_mongos
    before(:all) do
      if ClusterConfig.instance.topology == :sharded && SpecConfig.instance.addresses.length == 1
        skip 'Test requires a minimum of two mongoses if run in sharded topology'
      end

      if ClusterConfig.instance.topology == :load_balanced && SpecConfig.instance.single_mongos?
        skip 'Test requires a minimum of two mongoses if run in load-balanced topology'
      end
    end
  end

  # In sharded topology operations are distributed to the mongoses.
  # When we set fail points, the fail point may be set on one mongos and
  # operation may be executed on another mongos, causing failures.
  # Tests that are not setting targeted fail points should utilize this
  # method to restrict themselves to single mongos.
  #
  # In load-balanced topology, the same problem can happen when there is
  # more than one mongos behind the load balancer.
  def require_no_multi_shard
    before(:all) do
      if ClusterConfig.instance.topology == :sharded && SpecConfig.instance.addresses.length > 1
        skip 'Test requires a single mongos if run in sharded topology'
      end
      if ClusterConfig.instance.topology == :load_balanced && !SpecConfig.instance.single_mongos?
        skip 'Test requires a single mongos, as indicated by SINGLE_MONGOS=1 environment variable, if run in load-balanced topology'
      end
    end
  end

  def require_enterprise
    before(:all) do
      unless ClusterConfig.instance.enterprise?
        skip 'Test requires enterprise build of MongoDB'
      end
    end
  end

  def require_libmongocrypt
    before(:all) do
      # If FLE is set in environment, the entire test run is supposed to
      # include FLE therefore run the FLE tests.
      if (ENV['LIBMONGOCRYPT_PATH'] || '').empty? && (ENV['FLE'] || '').empty?
        skip 'Test requires path to libmongocrypt to be specified in LIBMONGOCRYPT_PATH env variable'
      end
    end
  end

  def min_libmongocrypt_version(version)
    require_libmongocrypt
    before(:all) do
      actual_version = Gem::Version.new(Mongo::Crypt::Binding.mongocrypt_version(nil))
      min_version = Gem::Version.new(version)
      unless actual_version >= min_version
        skip "libmongocrypt version #{min_version} required, but version #{actual_version} is available"
      end
    end
  end

  def require_no_libmongocrypt
    before(:all) do
      if ENV['LIBMONGOCRYPT_PATH']
        skip 'Test requires libmongocrypt to not be configured'
      end
    end
  end
end
# rubocop:enable RSpec/BeforeAfterAll
