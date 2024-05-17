# frozen_string_literal: true

module ActiveDocument
  module Macros

    def use_spec_active_document_config
      around do |example|
        config_path = File.join(File.dirname(__FILE__), '..', 'config', 'active_document.yml')

        ActiveDocument::Clients.clear
        ActiveDocument.load!(config_path, :test)

        begin
          example.run
        ensure
          ActiveDocument::Config.reset
        end
      end
    end

    def config_override(key, value)
      around do |example|
        existing = ActiveDocument.send(key)

        ActiveDocument.send(:"#{key}=", value)

        example.run

        ActiveDocument.send(:"#{key}=", existing)
      end
    end

    def with_config_values(key, *values, &block)
      values.each do |value|
        context "when #{key} is #{value}" do
          config_override key, value

          class_exec(value, &block)
        end
      end
    end

    def driver_config_override(key, value)
      around do |example|
        existing = Mongo.send(key)

        Mongo.send(:"#{key}=", value)

        example.run

        Mongo.send(:"#{key}=", existing)
      end
    end

    def with_driver_config_values(key, *values, &block)
      values.each do |value|
        context "when #{key} is #{value}" do
          driver_config_override key, value

          class_exec(value, &block)
        end
      end
    end

    def restore_config_clients
      around do |example|
        # Duplicate the config because some tests mutate it.
        old_config = ActiveDocument::Config.clients.dup
        example.run
        ActiveDocument::Config.send(:clients=, old_config)
      end
    end

    def query_cache_enabled
      around do |example|
        Mongo::QueryCache.cache do
          example.run
        end
      end
    end

    def override_query_cache(enabled)
      around do |example|
        cache_enabled = Mongo::QueryCache.enabled?
        Mongo::QueryCache.enabled = enabled
        example.run
        Mongo::QueryCache.enabled = cache_enabled
      end
    end

    # Override the global persistence context.
    #
    # @param [ :client, :database ] component The component to override.
    # @param [ Object ] value The value to override to.
    def persistence_context_override(component, value)
      around do |example|
        meth = "#{component}_override"
        old_value = ActiveDocument::Threaded.send(meth)
        ActiveDocument::Threaded.send(:"#{meth}=", value)
        example.run
        ActiveDocument::Threaded.send(:"#{meth}=", old_value)
      end
    end

    def time_zone_override(time_zone)
      around do |example|
        Time.use_zone(time_zone) { example.run }
      end
    end

    def with_default_i18n_configs
      around do |example|
        I18n.locale = :en
        I18n.default_locale = :en
        I18n.try(:fallbacks=, I18n::Locale::Fallbacks.new)
        I18n.enforce_available_locales = false
        example.run
      ensure
        I18n.locale = :en
        I18n.default_locale = :en
        I18n.try(:fallbacks=, I18n::Locale::Fallbacks.new)
        I18n.enforce_available_locales = false
      end
    end
  end
end
