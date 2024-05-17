# frozen_string_literal: true

namespace :db do
  namespace :active_document do

    desc 'Load ActiveDocument models into memory'
    task load_models: :environment do
      ActiveDocument.load_models
    end

    desc 'Create collections for ActiveDocument models'
    task create_collections: %i[environment load_models] do
      ActiveDocument::Tasks::Database.create_collections
    end

    desc 'Create indexes specified in ActiveDocument models'
    task create_indexes: %i[environment load_models] do
      ActiveDocument::Tasks::Database.create_indexes
    end

    desc 'Create search indexes specified in ActiveDocument models'
    task create_search_indexes: %i[environment load_models] do
      wait = ActiveDocument::Utils.truthy_string?(ENV['WAIT_FOR_SEARCH_INDEXES'] || '1')
      ActiveDocument::Tasks::Database.create_search_indexes(wait: wait)
    end

    desc 'Remove indexes that exist in the database but are not specified in ActiveDocument models'
    task remove_undefined_indexes: %i[environment load_models] do
      ActiveDocument::Tasks::Database.remove_undefined_indexes
    end

    desc 'Remove indexes specified in ActiveDocument models'
    task remove_indexes: %i[environment load_models] do
      ActiveDocument::Tasks::Database.remove_indexes
    end

    desc 'Remove search indexes specified in ActiveDocument models'
    task remove_search_indexes: %i[environment load_models] do
      ActiveDocument::Tasks::Database.remove_search_indexes
    end

    desc 'Shard collections with shard keys specified in ActiveDocument models'
    task shard_collections: %i[environment load_models] do
      ActiveDocument::Tasks::Database.shard_collections
    end

    desc 'Drop the database of the default ActiveDocument client'
    task drop: :environment do
      ActiveDocument::Clients.default.database.drop
    end

    desc 'Drop all non-system collections'
    task purge: :environment do
      ActiveDocument.purge!
    end

    namespace :create_collections do
      desc 'Drop and create collections for ActiveDocument models'
      task force: %i[environment load_models] do
        ActiveDocument::Tasks::Database.create_collections(force: true)
      end
    end
  end
end
