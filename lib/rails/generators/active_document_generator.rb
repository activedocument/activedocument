# frozen_string_literal: true

require 'rails/generators/named_base'
require 'rails/generators/active_model'

module ActiveDocument
  module Generators

    # Base generator class for adding ActiveDocument to Rails applications.
    class Base < ::Rails::Generators::NamedBase

      # Returns the path to the templates directory.
      #
      # @return [ String ] The path.
      def self.source_root
        @source_root ||= File.expand_path("../#{base_name}/#{generator_name}/templates", __FILE__)
      end
    end
  end
end

module Rails
  module Generators

    # Extension to Rails' GeneratedAttribute class.
    class GeneratedAttribute

      # Returns the ActiveDocument attribute type value for a given
      # input class type.
      #
      # @return [ String ] The type value.
      def type_class
        return 'Time' if type == :datetime
        return 'String' if type == :text
        return 'ActiveDocument::Boolean' if type == :boolean

        type.to_s.camelcase
      end
    end
  end
end
