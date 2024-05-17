# frozen_string_literal: true

require 'rails'
require 'rails/active_document'

module Rails
  module ActiveDocument

    # Hooks ActiveDocument into Rails 3 and higher.
    class Railtie < Rails::Railtie

      console do |app|
        if app.sandbox?
          require 'active_document/railties/console_sandbox'
          start_sandbox
        end
      end

      # Mapping of rescued exceptions to HTTP responses
      #
      # @example
      #   railtie.rescue_responses
      #
      # @ return [Hash] rescued responses
      def self.rescue_responses
        {
          'ActiveDocument::Errors::DocumentNotFound' => :not_found,
          'ActiveDocument::Errors::Validations' => 422
        }
      end

      config.app_generators.orm :mongoid, migration: false

      config.action_dispatch.rescue_responses&.merge!(rescue_responses)

      rake_tasks do
        load 'mongoid/railties/database.rake'
      end

      # Exposes ActiveDocument's configuration to the Rails application configuration.
      #
      # @example Set up configuration in the Rails app.
      #   module MyApplication
      #     class Application < Rails::Application
      #       config.mongoid.logger = Logger.new(STDERR, :warn)
      #     end
      #   end
      config.mongoid = ::ActiveDocument::Config

      # Initialize ActiveDocument. This will look for a activedocument.yml in the config
      # directory and configure mongoid appropriately.
      #
      # It runs after all config/initializers have loaded, so that the YAML
      # options can override options specified in
      # (e.g.) config/initializers/mongoid.rb.
      initializer 'mongoid.load-config', after: :load_config_initializers do
        config_file = Rails.root.join('config/activedocument.yml')
        if config_file.file?
          begin
            ::ActiveDocument.load!(config_file)
          rescue ::ActiveDocument::Errors::NoClientsConfig,
                 ::ActiveDocument::Errors::NoDefaultClient,
                 ::ActiveDocument::Errors::NoClientDatabase,
                 ::ActiveDocument::Errors::NoClientHosts => e
            handle_configuration_error(e)
          end
        end
      end

      # Set the proper error types for Rails. DocumentNotFound errors should be
      # 404s and not 500s, validation errors are 422s.
      config.after_initialize do
        unless config.action_dispatch.rescue_responses
          ActionDispatch::ShowExceptions.rescue_responses.update(Railtie.rescue_responses)
        end
        Mongo::Logger.logger = ::ActiveDocument.logger
      end

      # Due to all models not getting loaded and messing up inheritance queries
      # and indexing, we need to preload the models in order to address this.
      #
      # This will happen for every request in development, once in other
      # environments.
      initializer 'mongoid.preload-models' do |app|
        config.to_prepare do
          ::Rails::ActiveDocument.preload_models(app)
        end
      end

      # Rails runs all initializers first before getting into any generator
      # code, so we have no way in the initializer to know if we are
      # generating a activedocument.yml. So instead of failing, we catch all the
      # errors and print them out.
      def handle_configuration_error(error)
        ::ActiveDocument.logger.error 'There is a configuration error with the current activedocument.yml.'
        ::ActiveDocument.logger.error error.message
      end

      # Include Controller extension that measures ActiveDocument runtime
      # during request processing. The value then appears in Rails'
      # instrumentation event `process_action.action_controller`.
      #
      # The measurement is made via internal Mongo monitoring subscription
      initializer 'mongoid.runtime-metric' do
        require 'active_document/railties/controller_runtime'

        ActiveSupport.on_load :action_controller do
          include ::ActiveDocument::Railties::ControllerRuntime::ControllerExtension
        end

        Mongo::Monitoring::Global.subscribe Mongo::Monitoring::COMMAND,
                                            ::ActiveDocument::Railties::ControllerRuntime::Collector.new
      end

      # Add custom serializers for BSON::ObjectId
      initializer 'mongoid.active_job.custom_serializers' do
        ActiveSupport.on_load :active_job do
          require 'active_document/railties/bson_object_id_serializer'

          ActiveJob::Serializers.add_serializers(
            [::ActiveDocument::Railties::ActiveJobSerializers::BsonObjectIdSerializer]
          )
        end
      end
    end
  end
end
