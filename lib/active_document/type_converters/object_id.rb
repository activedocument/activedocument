# frozen_string_literal: true

module ActiveDocument
  module Extensions

    # Adds type-casting behavior to BSON::ObjectId.
    module ObjectId

      # Evolve the object id.
      #
      # @example Evolve the object id.
      #   object_id.to_query_object_id
      #
      # @return [ BSON::ObjectId ] self.
      def to_query_object_id
        self
      end
      alias_method :to_database_object_id, :to_query_object_id

      module ClassMethods

        # Evolve the object into a mongo-friendly value to query with.
        #
        # @example Evolve the object.
        #   ObjectId.evolve(id)
        #
        # @param [ Object ] object The object to evolve.
        #
        # @return [ BSON::ObjectId ] The object id.
        def evolve(object)
          object.to_query_object_id
        end

        # Convert the object into a mongo-friendly value to store.
        #
        # @example Convert the object.
        #   ObjectId.mongoize(id)
        #
        # @param [ Object ] object The object to convert.
        #
        # @return [ BSON::ObjectId ] The object id.
        def to_database_casted(object)
          object.to_database_object_id
        end
      end
    end
  end
end

BSON::ObjectId.include ActiveDocument::Extensions::ObjectId
BSON::ObjectId.extend(ActiveDocument::Extensions::ObjectId::ClassMethods)
