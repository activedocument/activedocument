# frozen_string_literal: true

module ActiveDocument
  module Extensions

    # Adds type-casting behavior to Symbol class.
    module Symbol

      module ClassMethods

        # Turn the object from the ruby type we deal with to a Mongo friendly
        # type.
        #
        # @example Mongoize the object.
        #   Symbol.mongoize("123.11")
        #
        # @param [ Object ] object The object to mongoize.
        #
        # @return [ Symbol | nil ] The object mongoized or nil.
        def mongoize(object)
          return if object.nil?

          return object.to_sym if object.respond_to?(:to_sym)

          ActiveDocument::RawValue.new(object, 'Symbol')
        end
        alias_method :demongoize, :mongoize
      end
    end
  end
end

Symbol.include ActiveDocument::Extensions::Symbol
Symbol.extend(ActiveDocument::Extensions::Symbol::ClassMethods)
