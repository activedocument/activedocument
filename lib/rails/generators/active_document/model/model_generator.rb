# frozen_string_literal: true

require 'rails/generators/active_document_generator'

module ActiveDocument
  module Generators

    # Generator class for ActiveDocument model files.
    class ModelGenerator < Base

      desc 'Creates a ActiveDocument model'
      argument :attributes, type: :array, default: [], banner: 'field:type field:type'

      check_class_collision

      class_option :timestamps, type: :boolean, default: true
      class_option :parent,     type: :string, desc: 'The parent class for the generated model'
      class_option :collection, type: :string, desc: "The collection for storing model's documents"

      # Creates a model file from a template.
      def create_model_file
        template 'model.rb.tt', File.join('app/models', class_path, "#{file_name}.rb")
      end

      hook_for :test_framework
    end
  end
end
