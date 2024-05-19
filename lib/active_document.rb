# frozen_string_literal: true

require 'active_document/version'

require 'forwardable'
require 'time'
require 'set'

require 'active_support'
require 'active_support/core_ext'
require 'active_support/json'
require 'active_support/inflector'
require 'active_support/time_with_zone'
require 'active_model'

require 'concurrent-ruby'

require 'mongo'
require 'mongo/active_support'

require 'active_document/deprecable'
require 'active_document/config'
require 'active_document/persistence_context'
require 'active_document/loadable'
require 'active_document/loggable'
require 'active_document/clients'
require 'active_document/document'
require 'active_document/tasks/database'
require 'active_document/tasks/encryption'
require 'active_document/warnings'
require 'active_document/utils'

# If we are using Rails then we will include the ActiveDocument railtie.
# This configures initializers required to integrate ActiveDocument with Rails.
require 'active_document/railtie' if defined?(Rails)

# Add English locale config to load path by default.
I18n.load_path << File.join(File.dirname(__FILE__), 'config', 'locales', 'en.yml')

# Top-level module for project.
module ActiveDocument
  extend Forwardable
  extend Loggable
  extend Loadable
  extend self
  extend Clients::Sessions::ClassMethods

  # A string added to the platform details of Ruby driver client handshake documents.
  PLATFORM_DETAILS = "active_document-#{VERSION}".freeze # rubocop:disable Style/RedundantFreeze

  # The minimum MongoDB version supported.
  MONGODB_VERSION = '2.6.0'

  # Sets the ActiveDocument configuration options. Best used by passing a block.
  #
  # @example Set up configuration options.
  #   ActiveDocument.configure do |config|
  #     config.connect_to("active_document_test")
  #
  #     config.clients.default = {
  #       hosts: ["localhost:27017"],
  #       database: "active_document_test",
  #     }
  #   end
  #
  # @example Using a block without an argument. Use `config` inside
  #   the block to perform variable assignment.
  #
  #   ActiveDocument.configure do
  #     connect_to("active_document_test")
  #
  #     config.preload_models = true
  #
  # @return [ Config ] The configuration object.
  def configure(&block)
    return Config unless block

    block.arity == 0 ? Config.instance_exec(&block) : yield(Config)
  end

  # Convenience method for getting the default client.
  #
  # @example Get the default client.
  #   ActiveDocument.default_client
  #
  # @return [ Mongo::Client ] The default client.
  def default_client
    Clients.default
  end

  # Disconnect all active clients.
  #
  # @example Disconnect all active clients.
  #   ActiveDocument.disconnect_clients
  #
  # @return [ true ] True.
  def disconnect_clients
    Clients.disconnect
  end

  # Reconnect all active clients.
  #
  # @example Reconnect all active clients.
  #   ActiveDocument.reconnect_clients
  #
  # @return [ true ] True.
  def reconnect_clients
    Clients.reconnect
  end

  # Convenience method for getting a named client.
  #
  # @example Get a named client.
  #   ActiveDocument.client(:default)
  #
  # @return [ Mongo::Client ] The named client.
  def client(name)
    Clients.with_name(name)
  end

  # Take all the public instance methods from the Config singleton and allow
  # them to be accessed through the ActiveDocument module directly.
  #
  # @example Delegate the configuration methods.
  #   ActiveDocument.database = Mongo::Connection.new.db("test")
  def_delegators Config, *(Config.public_instance_methods(false) - %i[logger= logger])

  # Define persistence context that is used when a transaction method is called
  # on ActiveDocument module.
  #
  # @api private
  def persistence_context
    PersistenceContext.get(ActiveDocument) || PersistenceContext.new(ActiveDocument)
  end

  # Define client that is used when a transaction method is called
  # on ActiveDocument module. This MUST be the default client.
  #
  # @api private
  def storage_options
    { client: :default }
  end

  # Module used to prepend the discriminator key assignment function to change
  # the value assigned to the discriminator key to a string.
  #
  # @api private
  module GlobalDiscriminatorKeyAssignment

    # This class is used for obtaining the method definition location for
    # ActiveDocument methods.
    class InvalidFieldHost
      include ActiveDocument::Document
    end

    # Sets the global discriminator key name.
    #
    # @param [ String | Symbol ] value The new discriminator key name.
    def discriminator_key=(value)
      ActiveDocument::Fields::Validators::Macro.validate_field_name(InvalidFieldHost, value)
      value = value.to_s
      super
    end
  end

  class << self
    prepend GlobalDiscriminatorKeyAssignment
  end
end
