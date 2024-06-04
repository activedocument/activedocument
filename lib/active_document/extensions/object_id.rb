# frozen_string_literal: true

module ActiveDocument
  module Extensions

    # Adds type-casting behavior to BSON::ObjectId.
    module ObjectId

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
          ActiveDocument::TypeConverters::BsonObjectIdMulti.to_query_cast(object)
        end

        # Convert the object into a mongo-friendly value to store.
        #
        # @example Convert the object.
        #   ObjectId.mongoize(id)
        #
        # @param [ Object ] object The object to convert.
        #
        # @return [ BSON::ObjectId ] The object id.
        def mongoize(object)
          ActiveDocument::TypeConverters::BsonObjectIdMulti.to_database_cast(object)
        end
      end
    end
  end
end

BSON::ObjectId.include ActiveDocument::Extensions::ObjectId
BSON::ObjectId.extend(ActiveDocument::Extensions::ObjectId::ClassMethods)
