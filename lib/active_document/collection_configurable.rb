# frozen_string_literal: true

module ActiveDocument

  # Encapsulates behavior around defining collections.
  module CollectionConfigurable
    extend ActiveSupport::Concern

    module ClassMethods
      # Create the collection for the called upon ActiveDocument model.
      #
      # This method does not re-create existing collections.
      #
      # If the document includes `store_in` macro with `collection_options` key,
      #   these options are used when creating the collection.
      #
      # @param [ true | false ] force If true, the method will drop existing
      #   collections before creating new ones. If false, the method will create
      #   only new collection (that do not exist in the database).
      #
      # @raise [ Errors::CreateCollectionFailure ] If collection creation failed.
      # @raise [ Errors::DropCollectionFailure ] If an attempt to drop collection failed.
      def create_collection(force: false)
        # This is probably an anonymous class, we ignore them.
        return if collection_name.empty?

        # We do not do anything with system collections.
        return if collection_name.start_with?('system.')

        collection.drop if force

        if (coll_options = collection.database.list_collections(filter: { name: collection_name.to_s }).first)
          raise Errors::DropCollectionFailure.new(collection_name) if force

          logger.debug(
            "MONGOID: Collection '#{collection_name}' already exists " \
            "in database '#{database_name}' with options '#{coll_options}'."
          )
        else
          begin
            collection.database[collection_name, storage_options.fetch(:collection_options, {})].create
          rescue Mongo::Error::OperationFailure => e
            raise Errors::CreateCollectionFailure.new(
              collection_name,
              storage_options[:collection_options],
              e
            )
          end
        end
      end
    end
  end
end
