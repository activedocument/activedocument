# frozen_string_literal: true

module ActiveDocument
  module TypeConverters

    # Type-casting behavior for BSON::ObjectId.
    module BsonObjectId
      extend self

      # Prepare a BSON::ObjectId to store in the database.
      #
      # @example Prepare a Time object to store in database.
      #   TypeConverters::BsonObjectId.to_database(object_id)
      #
      # @return [ BSON::ObjectId | nil ] The prepared BSON::ObjectId or nil.
      def to_database(value)
        value
      end

      # Doc
      # TODO: Add doc
      def to_database_cast(value)
        return if value.blank?

        case value
        when BSON::ObjectId
          value
        when String
          cast_string(value)
        when Hash
          cast_hash(value)
        else
          cast_object(value)
        end
      end
      alias_method :to_ruby_cast, :to_database_cast

      def to_query_cast(value)
        # TODO: is this needed?
        return ActiveDocument::RawValue('') if value == ''

        to_database_cast(value)
      end

      private

      def cast_string(value)
        if BSON::ObjectId.legal?(value)
          BSON::ObjectId.from_string(value)
        else
          cast_object(value)
        end
      end

      def cast_hash(value)
        if (id = value['$oid']) && BSON::ObjectId.legal?(id)
          BSON::ObjectId.from_string(id)
        else
          cast_object(value)
        end
      end

      def cast_object(value)
        ActiveDocument::RawValue(value)
        # TODO: ActiveDocument::RawValue(value, 'BSON::ObjectId')
      end
    end
  end
end
