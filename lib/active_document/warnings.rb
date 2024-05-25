# frozen_string_literal: true

module ActiveDocument

  # Encapsulates behavior around logging and caching warnings so they are only
  # logged once.
  #
  # @api private
  module Warnings

    class << self

      # Define a warning message method for the given id.
      #
      # @param [ Symbol ] id The warning identifier.
      # @param [ String ] message The warning message.
      #
      # @api private
      def warning(id, message)
        singleton_class.class_eval do
          define_method(:"warn_#{id}") do
            return if instance_variable_get(:"@#{id}")

            ActiveDocument.logger.warn(message)
            instance_variable_set(:"@#{id}", true)
          end
        end
      end
    end

    warning :geo_haystack_deprecated, 'The geoHaystack type is deprecated.'
    warning :legacy_readonly, 'The readonly! method will only mark the document readonly when the legacy_readonly feature flag is switched off.'
    warning :mutable_ids, 'Ignoring updates to immutable attribute `_id`. Please set ActiveDocument::Config.immutable_ids to true and update your code so that `_id` is never updated.'
  end
end
