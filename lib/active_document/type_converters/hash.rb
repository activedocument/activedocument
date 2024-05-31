# frozen_string_literal: true

module ActiveDocument
  module Extensions

    # Adds type-casting behavior to Hash class.
    module Hash

      # Evolves each value in the hash to an object id if it is convertable.
      #
      # @example Convert the hash values.
      #   { field: id }.to_query_object_id
      #
      # @return [ Hash ] The converted hash.
      def to_query_object_id
        transform_values!(&:to_query_object_id)
      end

      # Mongoizes each value in the hash to an object id if it is convertable.
      #
      # @example Convert the hash values.
      #   { field: id }.to_database_object_id
      #
      # @return [ Hash ] The converted hash.
      def to_database_object_id
        if (id = self['$oid'])
          BSON::ObjectId.from_string(id)
        else
          transform_values!(&:to_database_object_id)
        end
      end

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
        def to_database_casted(object)
          return if object.nil?

          case object
          when BSON::Document
            object.dup.transform_values!(&:mongoize)
          when Hash
            BSON::Document.new(object.transform_values(&:mongoize))
          end
        end
      end
    end
  end
end

Hash.include(ActiveDocument::Extensions::Hash)
Hash.extend(ActiveDocument::Extensions::Hash::ClassMethods)
