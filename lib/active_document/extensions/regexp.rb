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
        def mongoize(object)
          return if object.nil?

          case object
          when String
            ::Regexp.new(object)
          when ::Regexp
            object
          when BSON::Regexp::Raw
            object.compile
          else
            ActiveDocument::RawValue(object, 'Regexp')
          end
        rescue RegexpError => e
          ActiveDocument::RawValue(object, 'Regexp', e)
        end
        alias_method :demongoize, :mongoize
      end
    end
  end
end

Regexp.extend(ActiveDocument::Extensions::Regexp::ClassMethods)
