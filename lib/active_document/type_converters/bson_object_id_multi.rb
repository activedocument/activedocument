# frozen_string_literal: true

module ActiveDocument
  module TypeConverters

    # Type-casting behavior for BSON::ObjectId, allowing arrays and hashes.
    module BsonObjectIdMulti
      extend self

      # Doc
      # TODO: Add doc
      def to_database_cast(value)
        return if value.blank?

        case value
        when Array
          value = value.map { |v| to_database_cast(v) }
          value.compact!
          value
        when Hash
          if (id = value['$oid']) && BSON::ObjectId.legal?(id)
            BSON::ObjectId.from_string(id)
          else
            value.transform_values { |v| to_database_cast(v) }
          end
        when String
          if BSON::ObjectId.legal?(value)
            BSON::ObjectId.from_string(value)
          else
            value # TODO: RawValue?
          end
        else
          value # TODO: RawValue?
        end
      end
      alias_method :to_query_cast, :to_database_cast
      alias_method :to_ruby_cast, :to_database_cast
    end
  end
end
