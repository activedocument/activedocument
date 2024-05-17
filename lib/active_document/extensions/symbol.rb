# frozen_string_literal: true

module ActiveDocument
  module Extensions

    # Adds type-casting behavior to Symbol class.
    module Symbol

      # Is the symbol a valid value for a ActiveDocument id?
      #
      # @example Is the string an id value?
      #   :_id.active_document_id?
      #
      # @return [ true | false ] If the symbol is :id or :_id.
      # @deprecated
      def active_document_id?
        to_s.active_document_id?
      end
      ActiveDocument.deprecate(self, :active_document_id?)

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
          object.try(:to_sym)
        end
        alias_method :demongoize, :mongoize
      end
    end
  end
end

Symbol.include ActiveDocument::Extensions::Symbol
Symbol.extend(ActiveDocument::Extensions::Symbol::ClassMethods)
