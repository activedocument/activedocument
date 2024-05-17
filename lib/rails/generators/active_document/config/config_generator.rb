# frozen_string_literal: true

require 'rails/generators/active_document_generator'

module ActiveDocument
  module Generators

    # Generator class for ActiveDocument configuration files.
    class ConfigGenerator < Rails::Generators::Base
      desc 'Creates ActiveDocument configuration files'

      argument :database_name, type: :string, optional: true

      # Returns the path to the templates directory.
      #
      # @return [ String ] The path.
      def self.source_root
        @source_root ||= File.expand_path('templates', __dir__)
      end

      # Returns the underscored name of the Rails application.
      #
      # @return [ String ] The app name.
      def app_name # :nodoc:
        app_cls = Rails.application.class
        parent = begin
          # Rails 6.1+
          app_cls.module_parent_name
        rescue NoMethodError
          app_cls.parent.to_s
        end
        parent.underscore
      end

      # Creates a +activedocument.yml+ config file from a template.
      def create_config_file
        template 'activedocument.yml', File.join('config', 'activedocument.yml')
      end

      # Creates a +active_document.rb+ initializer file from a template.
      def create_initializer_file
        template 'mongoid.rb', File.join('config', 'initializers', 'mongoid.rb')
      end
    end
  end
end
