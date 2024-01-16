# frozen_string_literal: true

require 'i18n'

module Constraints

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

  [
    [:ruby, 'Ruby', RUBY_VERSION],
    [:rails, 'Rails', ActiveSupport.version.to_s],
    [:driver, 'Mongo Driver', Mongo::VERSION],
    [:bson, 'BSON Ruby', BSON::VERSION],
    [:server, 'MongoDB Server', -> { ClusterConfig.instance.server_version }],
    [:fcv, 'MongoDB Server FCV', -> { ClusterConfig.instance.fcv_ish }],
    [:libmongocrypt, 'libmongocrypt', -> { Mongo::Crypt::Binding.mongocrypt_version(nil) }]
  ].each do |meth, name, current_version|
    %i[min max].each do |dir| # rubocop:disable Performance/CollectionLiteralInLoop
      define_method(:"#{dir}_#{meth}_version") do |version|
        current_version = current_version.call if current_version.is_a?(Proc)
        before(:all) do
          if Constraints.send(:"#{dir}_version?", current_version, version)
            skip "#{name} version #{version} or #{dir == :min ? 'higher' : 'lower'} " \
                 "is required (using #{current_version})"
          end
        end
      end
    end
  end

  def local_env(env = nil)
    around do |example|
      saved_env = ENV.to_h
      ENV.update(env || yield)
      example.run
    ensure
      ENV.replace(saved_env)
    end
  end

  def require_mri
    before(:all) do
      unless SpecConfig.instance.mri?
        skip "MRI required, we have #{SpecConfig.instance.platform}"
      end
    end
  end

  def require_topology(*topologies)
    invalid_topologies = topologies - %i[single replica_set sharded load_balanced]

    unless invalid_topologies.empty?
      raise ArgumentError.new("Invalid topologies requested: #{invalid_topologies.join(', ')}")
    end

    before(:all) do
      topology = ClusterConfig.instance.topology
      unless topologies.include?(topology)
        skip "Topology #{topologies.join(' or ')} required, we have #{topology}"
      end
    end
  end

  def require_transaction_support
    before(:all) do
      case ClusterConfig.instance.topology
      when :single
        skip 'Transactions tests require a replica set or a sharded cluster'
      when :replica_set, :sharded, :load_balanced
        # ok
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
      unless ENV['LIBMONGOCRYPT_PATH'].present? || ENV['FLE'].present?
        skip 'Test requires path to libmongocrypt to be specified in LIBMONGOCRYPT_PATH env variable'
      end
    end
  end

  def require_no_libmongocrypt
    before(:all) do
      if ENV['LIBMONGOCRYPT_PATH'].present?
        skip 'Test requires libmongocrypt to not be configured'
      end
    end
  end

  def min_version?(current_version, required_version)
    version_comparator(current_version, required_version) <= 0
  end
  module_function :min_version?

  def max_version?(current_version, required_version)
    version_comparator(current_version, required_version) >= 0
  end
  module_function :max_version?

  def version_comparator(current_version, required_version)
    required_version = required_version.split('.').map(&:to_i)
    current_version = current_version.split('.').first(required_version.length).map(&:to_i)
    current_version <=> required_version
  end
  module_function :version_comparator
end
