# frozen_string_literal: true

module ActiveDocument
  module Extensions

    # Adds type-casting behavior to Hash class.
    module Hash

      # Turn the object from the ruby type we deal with to a Mongo friendly
      # type.
      #
      # @example Mongoize the object.
      #   object.mongoize
      #
      # @return [ Hash | nil ] The object mongoized or nil.
      def mongoize
        ::Hash.mongoize(self)
      end

      # Can the size of this object change?
      #
      # @example Is the hash resizable?
      #   {}.resizable?
      #
      # @return [ true ] true.
      def resizable?
        true
      end

      module ClassMethods

        # Turn the object from the ruby type we deal with to a Mongo friendly
        # type.
        #
        # @example Mongoize the object.
        #   Hash.mongoize([ 1, 2, 3 ])
        #
        # @param [ Object ] object The object to mongoize.
        #
        # @return [ Hash | nil ] The object mongoized or nil.
        def mongoize(object)
          return if object.nil?

          case object
          when BSON::Document
            object.dup.transform_values!(&:mongoize)
          when Hash
            BSON::Document.new(object.transform_values(&:mongoize))
          end
        end

        # Can the size of this object change?
        #
        # @example Is the hash resizable?
        #   {}.resizable?
        #
        # @return [ true ] true.
        def resizable?
          true
        end
      end
    end
  end
end

Hash.include(ActiveDocument::Extensions::Hash)
Hash.extend(ActiveDocument::Extensions::Hash::ClassMethods)
