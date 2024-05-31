# frozen_string_literal: true

module ActiveDocument
  module Extensions

    # Adds type-casting behavior to Regexp class.
    module Regexp

      module ClassMethods

        # Turn the object from the ruby type we deal with to a Mongo friendly
        # type.
        #
        # @example Mongoize the object.
        #   Regexp.mongoize(/\A[abc]/)
        #
        # @param [ Object ] object The object to mongoize.
        #
        # @return [ Regexp | nil ] The object mongoized or nil.
        def to_database_casted(object)
          return if object.nil?

          case object
          when String then ::Regexp.new(object)
          when ::Regexp then object
          when BSON::Regexp::Raw then object.compile
          end
        rescue RegexpError
          nil
        end
        alias_method :demongoize, :mongoize
      end
    end
  end
end

Regexp.extend(ActiveDocument::Extensions::Regexp::ClassMethods)
