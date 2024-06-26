# frozen_string_literal: true

module ActiveDocument
  module TypeConverters

    # Type-casting behavior for BSON::ObjectId, allowing arrays and hashes.
    module ForeignKey
      extend self

      # Cast an object to BSON::ObjectId to store in the database.
      #
      # @example Prepare a BSON::ObjectId to store in database.
      #   TypeConverters::BsonObjectId.to_database(object_id)
      #
      # @return [ BSON::ObjectId | nil ] The prepared BSON::ObjectId or nil.
      def to_database_cast(value)
        return if value.nil? || value == ''

        value = value.to_a if value.is_a?(Set)

        case value
        when Array
          value = value.map! { |v| to_database_cast(v) }
          value.compact!
          value
        when Hash
          if (id = value['$oid']) && BSON::ObjectId.legal?(id)
            BSON::ObjectId.from_string(id)
          else
            value.transform_values! { |v| to_database_cast(v) }
          end
        when String
          if BSON::ObjectId.legal?(value)
            BSON::ObjectId.from_string(value)
          else
            value # TODO: RawValue?
          end
        when ActiveDocument::Document,
             ActiveDocument::Association::Referenced::BelongsTo::Proxy
          value._id
        when ActiveDocument::Association::One
          value._target._id
        else
          value # TODO: RawValue?
        end
      end
      alias_method :to_ruby_cast, :to_database_cast

      # Cast an object to BSON::ObjectId to use in a query.
      #
      # @example Prepare a BSON::ObjectId to use in a query.
      #   TypeConverters::BsonObjectId.to_database(object_id)
      #
      # @return [ BSON::ObjectId | nil ] The prepared BSON::ObjectId or nil.
      def to_query_cast(value)
        # TODO: is this needed?
        return value if value == ''

        value = value.to_a if value.is_a?(Set)

        case value
        when Array
          value.map! { |v| to_query_cast(v) }
        when Hash
          if (id = value['$oid']) && BSON::ObjectId.legal?(id)
            BSON::ObjectId.from_string(id)
          else
            value.transform_values! { |v| to_query_cast(v) }
          end
        else
          to_database_cast(value)
        end
      end
    end
  end
end
