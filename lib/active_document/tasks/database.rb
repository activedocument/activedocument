# frozen_string_literal: true

module ActiveDocument
  module Tasks

    # Utility module to manage database collections, indexes, sharding, etc.
    # Invoked from Rake tasks.
    module Database
      extend self

      # Create collections for each model given the provided globs and the class is
      # not embedded.
      #
      # @param [ Array<ActiveDocument::Document> ] models. Array of document classes for
      #   which collections should be created. Defaulted to all document classes
      #   in the application.
      # @param [ true | false ] force If true, the method will drop existing
      #   collections before creating new ones. If false, the method will create
      #   only new collection (that do not exist in the database).
      def create_collections(models = ::ActiveDocument.models, force: false)
        models.each do |model|
          if !model.embedded? || model.cyclic?
            model.create_collection(force: force)
            logger.info("MONGOID: Created collection for #{model}:")
          else
            logger.info("MONGOID: collection options ignored on: #{model}, please define in the root model.")
          end
        rescue StandardError
          logger.error "error while creating collection for #{model}"
          raise
        end
      end

      # Create indexes for each model given the provided globs and the class is
      # not embedded.
      #
      # @example Create all the indexes.
      #   ActiveDocument::Tasks::Database.create_indexes
      #
      # @return [ Array<Class> ] The indexed models.
      def create_indexes(models = ::ActiveDocument.models)
        models.each do |model|
          next if model.index_specifications.empty?

          if !model.embedded? || model.cyclic?
            model.create_indexes
            logger.info("MONGOID: Created indexes on #{model}:")
            model.index_specifications.each do |spec|
              logger.info("MONGOID: Index: #{spec.key}, Options: #{spec.options}")
            end
            model
          else
            logger.info("MONGOID: Index ignored on: #{model}, please define in the root model.")
            nil
          end
        end.compact
      end

      # Submit requests for the search indexes to be created. This will happen
      # asynchronously. If "wait" is true, the method will block while it
      # waits for the indexes to be created.
      #
      # @param [ Array<ActiveDocument::Document> ] models the models to build search
      #   indexes for.
      # @param [ true | false ] wait whether to wait for the indexes to be
      #   built.
      def create_search_indexes(models = ::ActiveDocument.models, wait: true)
        searchable = models.select { |m| m.search_index_specs.any? }

        # queue up the search index creation requests
        index_names_by_model = searchable.each_with_object({}) do |model, obj|
          logger.info("MONGOID: Creating search indexes on #{model}...")
          obj[model] = model.create_search_indexes
        end

        wait_for_search_indexes(index_names_by_model) if wait
      end

      # Return the list of indexes by model that exist in the database but aren't
      # specified on the models.
      #
      # @example Return the list of unused indexes.
      #   ActiveDocument::Tasks::Database.undefined_indexes
      #
      # @return [ Array<Hash> ] The list of undefined indexes by model.
      def undefined_indexes(models = ::ActiveDocument.models)
        undefined_by_model = {}

        models.each do |model|
          next if model.embedded?

          model.collection.indexes(session: model.send(:_session)).each do |index|
            # ignore default index
            next if index['name'] == '_id_'

            key = index['key'].symbolize_keys
            spec = model.index_specification(key, index['name'])
            next if spec

            # index not specified
            undefined_by_model[model] ||= []
            undefined_by_model[model] << index
          end
        rescue Mongo::Error::OperationFailure => e
          logger.info("MONGOID: Could not get indexes for #{model}: #{e.message}")
        end

        undefined_by_model
      end

      # Remove indexes that exist in the database but aren't specified on the
      # models.
      #
      # @example Remove undefined indexes.
      #   ActiveDocument::Tasks::Database.remove_undefined_indexes
      #
      # @return [ Hash{Class => Array(Hash)}] The list of indexes that were removed by model.
      def remove_undefined_indexes(models = ::ActiveDocument.models)
        undefined_indexes(models).each do |model, indexes|
          indexes.each do |index|
            key = index['key'].symbolize_keys
            collection = model.collection
            collection.indexes(session: model.send(:_session)).drop_one(key)
            logger.info(
              "MONGOID: Removed index '#{index['name']}' on collection " \
              "'#{collection.name}' in database '#{collection.database.name}'."
            )
          end
        end
      end

      # Remove indexes for each model given the provided globs and the class is
      # not embedded.
      #
      # @example Remove all the indexes.
      #   ActiveDocument::Tasks::Database.remove_indexes
      #
      # @return [ Array<Class> ] The model classes whose indexes were successfully removed.
      def remove_indexes(models = ::ActiveDocument.models)
        models.filter_map do |model|
          next if model.embedded?

          begin
            model.remove_indexes
          rescue Mongo::Error::OperationFailure
            next
          end

          model
        end
      end

      # Remove all search indexes from the given models.
      #
      # @params [ Array<ActiveDocument::Document> ] models the models to remove
      #   search indexes from.
      def remove_search_indexes(models = ::ActiveDocument.models)
        models.each do |model|
          next if model.embedded?

          model.remove_search_indexes
        end
      end

      # Shard collections for models that declare shard keys.
      #
      # Returns the model classes that have had their collections sharded,
      # including model classes whose collections had already been sharded
      # prior to the invocation of this method.
      #
      # @example Shard all collections
      #   ActiveDocument::Tasks::Database.shard_collections
      #
      # @return [ Array<Class> ] The sharded models
      def shard_collections(models = ::ActiveDocument.models)
        models.filter_map do |model|
          next if model.shard_config.nil?

          if model.embedded? && !model.cyclic?
            logger.warn("MONGOID: #{model} has shard config but is embedded")
            next
          end

          unless model.collection.cluster.sharded?
            logger.warn("MONGOID: #{model} has shard config but is not persisted in a sharded cluster: #{model.collection.cluster.summary}")
            next
          end

          # Database of the collection must exist in order to run collStats.
          # Depending on server version, the collection itself must also
          # exist.
          # MongoDB does not have a command to create the database; the best
          # approximation of it is to create the collection we want.
          # On older servers, creating a collection that already exists is
          # an error.
          # Additionally, 3.6 and potentially older servers do not provide
          # the error code when they are asked to collStats a non-existent
          # collection (https://jira.mongodb.org/browse/SERVER-50070).
          stats = begin
            model.collection.database.command(collStats: model.collection.name).first
          rescue Mongo::Error::OperationFailure => e
            # Code 26 is database does not exist.
            # Code 8 is collection does not exist, as of 4.0.
            # On 3.6 and earlier match the text of exception message.
            if e.code == 26 || e.code == 8 ||
               (e.code.nil? && e.message =~ /not found/)
              model.collection.create

              model.collection.database.command(collStats: model.collection.name).first
            else
              raise
            end
          end

          if stats[:sharded]
            logger.info("MONGOID: #{model.collection.namespace} is already sharded for #{model}")
            next model
          end

          admin_db = model.collection.client.use(:admin).database
          admin_db.command(enableSharding: model.collection.database.name)

          begin
            admin_db.command(shardCollection: model.collection.namespace, **model.shard_config)
          rescue Mongo::Error::OperationFailure => e
            logger.error("MONGOID: Failed to shard collection #{model.collection.namespace} for #{model}: #{e.class}: #{e}")
            next
          end

          logger.info("MONGOID: Sharded collection #{model.collection.namespace} for #{model}")

          model
        end
      end

      private

      def logger
        ActiveDocument.logger
      end

      # Waits for the search indexes to be built on the given models.
      #
      # @param [ Hash<ActiveDocument::Document, Array<String>> ] models a mapping of
      #   index names for each model
      def wait_for_search_indexes(models)
        logger.info('MONGOID: Waiting for search indexes to be created')
        logger.info('MONGOID: Press ctrl-c to skip the wait and let the indexes be created in the background')

        models.each do |model, names|
          model.wait_for_search_indexes(names) do |status|
            if status.ready?
              logger.info("MONGOID: Search indexes on #{model} are READY")
            else
              print '.' # rubocop:disable Rails/Output
              $stdout.flush
            end
          end
        end
      rescue Interrupt
        # ignore ctrl-C here; we assume it is meant only to skip
        # the wait, and that subsequent tasks ought to continue.
        logger.info('MONGOID: Skipping the wait for search indexes; they will be created in the background')
      end
    end
  end
end