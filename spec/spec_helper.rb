# frozen_string_literal: true

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'simplecov'

SimpleCov.start do
  add_filter '/spec/'
end

require 'simplecov-cobertura'
SimpleCov.formatter = SimpleCov::Formatter::CoberturaFormatter

autoload :Timecop, 'timecop'
require 'support/spec_config'
require 'active_document'

# require all shared examples
Dir['./spec/support/shared/*.rb'].each { |file| require(file) }

MODELS = File.join(File.dirname(__FILE__), 'support/models')
$LOAD_PATH.unshift(MODELS)

require 'action_controller'
require 'rspec/retry'

if SpecConfig.instance.client_debug?
  ActiveDocument.logger.level = Logger::DEBUG
  Mongo::Logger.logger.level = Logger::DEBUG
else
  ActiveDocument.logger.level = Logger::INFO
  Mongo::Logger.logger.level = Logger::INFO
end

# When testing locally we use the database named active_document_test. However when
# tests are running in parallel in a CI environment we need to use different
# database names for each process running since we do not have transactions
# and want a clean slate before each spec run.
def database_id
  'active_document_test'
end

def database_id_alt
  'active_document_test_alt'
end

require 'support/cluster_config'
require 'support/client_registry'
require 'support/event_subscriber'
require 'support/authorization'
require 'support/expectations'
require 'support/helpers'
require 'support/macros'
require 'support/constraints'
require 'support/crypt'

use_ssl = %w[ssl 1 true].include?(ENV['SSL'])
ssl_options = { ssl: use_ssl }.freeze

# Give MongoDB servers time to start up in CI environments
if SpecConfig.instance.ci?
  starting = true
  client = Mongo::Client.new(SpecConfig.instance.addresses, ssl_options)
  while starting
    begin
      client.command(ping: 1)
      break
    rescue Mongo::Error::OperationFailure
      sleep(2)
      client.cluster.scan!
    end
  end
end

CONFIG = {
  clients: {
    default: {
      database: database_id,
      hosts: SpecConfig.instance.addresses,
      options: ssl_options.merge(
        server_selection_timeout: 3.42,
        wait_queue_timeout: 1,
        max_pool_size: 5,
        heartbeat_frequency: 180,
        user: SpecConfig.instance.uri.client_options[:user] || MONGOID_ROOT_USER.name,
        password: SpecConfig.instance.uri.client_options[:password] || MONGOID_ROOT_USER.password,
        auth_source: Mongo::Database::ADMIN
      )
    }
  },
  options: {
    belongs_to_required_by_default: false,
    log_level: if SpecConfig.instance.client_debug?
                 :debug
               else
                 :info
               end
  }
}.freeze

# Set the database that the spec suite connects to.
ActiveDocument.configure do |config|
  config.load_configuration(CONFIG)
end

# Autoload every model for the test suite that sits in spec/support/models.
Dir[File.join(MODELS, '*.rb')].each do |file|
  name = File.basename(file, '.rb')
  autoload name.camelize.to_sym, name
end

module ActiveDocument
  class Query
    include ActiveDocument::Criteria::Queryable
  end
end

ActiveSupport::Inflector.inflections do |inflect|
  inflect.irregular('canvas', 'canvases')
  inflect.singular('address_components', 'address_component')
end

I18n.config.enforce_available_locales = false

if %w[yes true 1].include?((ENV['TEST_I18N_FALLBACKS'] || '').downcase)
  require 'i18n/backend/fallbacks'
end

unless SpecConfig.instance.atlas?
  # The user must be created before any of the tests are loaded, until
  # https://jira.mongodb.org/browse/MONGOID-4827 is implemented.
  client = Mongo::Client.new(SpecConfig.instance.addresses, server_selection_timeout: 3.03)
  begin
    # Create the root user administrator as the first user to be added to the
    # database. This user will need to be authenticated in order to add any
    # more users to any other databases.
    client.database.users.create(MONGOID_ROOT_USER)
  rescue Mongo::Error::OperationFailure
  ensure
    client.close
  end
end

RSpec.configure do |config|
  config.raise_errors_for_deprecations!
  config.include(Helpers)
  config.include(ActiveDocument::Expectations)
  config.extend(Constraints)
  config.extend(ActiveDocument::Macros)

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:suite) do
    ActiveDocument.purge!
  end

  # Drop all collections and clear the identity map before each spec.
  config.before do
    cluster = ActiveDocument.default_client.cluster
    ActiveDocument.default_client.reconnect unless cluster.connected?
    ActiveDocument.default_client.collections.each(&:delete_many)
  end

  if SpecConfig.instance.mri? && !SpecConfig.instance.windows?
    require 'timeout_interrupt'
    timeout_lib = TimeoutInterrupt
  else
    require 'timeout'
    timeout_lib = Timeout
  end

  if SpecConfig.instance.ci? && %w[1 true yes].exclude?(ENV['INTERACTIVE']&.downcase)
    config.around do |example|
      timeout_lib.timeout(30) { example.run }
    end
  end

  config.around do |example|
    Time.use_zone('UTC') { example.run }
  end
end
