# frozen_string_literal: true

require 'active_document/changeable'
require 'active_document/collection_configurable'
require 'active_document/encryptable'
require 'active_document/findable'
require 'active_document/indexable'
require 'active_document/inspectable'
require 'active_document/interceptable'
require 'active_document/matcher'
require 'active_document/matchable'
require 'active_document/persistable'
require 'active_document/reloadable'
require 'active_document/search_indexable'
require 'active_document/selectable'
require 'active_document/scopable'
require 'active_document/serializable'
require 'active_document/shardable'
require 'active_document/stateful'
require 'active_document/cacheable'
require 'active_document/traversable'
require 'active_document/validatable'

module ActiveDocument

  # This module provides inclusions of all behavior in a ActiveDocument document.
  module Composable
    extend ActiveSupport::Concern

    # All modules that a +Document+ is composed of are defined in this
    # module, to keep the document class from getting too cluttered.
    included do
      extend Findable
    end

    include ActiveModel::Model
    include ActiveModel::ForbiddenAttributesProtection
    include ActiveModel::Serializers::JSON
    include Atomic
    include Changeable
    include Clients
    include CollectionConfigurable
    include Attributes
    include Fields
    include Indexable
    include Inspectable
    include Matchable
    include Persistable
    include Association
    include Reloadable
    include Scopable
    include SearchIndexable
    include Selectable
    include Serializable
    include Shardable
    include Stateful
    include Cacheable
    include Threaded::Lifecycle
    include Traversable
    include Validatable
    include Interceptable
    include Copyable
    include Equality
    include Encryptable

    MODULES = [
      Atomic,
      Attributes,
      Copyable,
      Changeable,
      Fields,
      Indexable,
      Inspectable,
      Interceptable,
      Matchable,
      Persistable,
      Association,
      Reloadable,
      Scopable,
      Serializable,
      Clients,
      Clients::Options,
      Shardable,
      Stateful,
      Cacheable,
      Threaded::Lifecycle,
      Traversable,
      Validatable,
      Equality,
      Association::Referenced::Syncable,
      Association::Macros,
      ActiveModel::Model,
      ActiveModel::Validations
    ].freeze

    # These are methods names defined in included blocks that may conflict
    # with user-defined association or field names.
    # They won't be in the list of Module.instance_methods on which the
    # #prohibited_methods code below is dependent so we must track them
    # separately.
    #
    # @return [ Array<Symbol> ] A list of reserved method names.
    RESERVED_METHOD_NAMES = %i[fields
                               aliased_fields
                               localized_fields
                               index_specifications
                               shard_key_fields
                               nested_attributes
                               readonly_attributes
                               storage_options
                               cascades
                               cyclic
                               cache_timestamp_format].freeze

    class << self

      # Get a list of methods that would be a bad idea to define as field names
      # or override when including ActiveDocument::Document.
      #
      # @example Bad thing!
      #   ActiveDocument::Components.prohibited_methods
      #
      # @return [ Array<Symbol> ]
      def prohibited_methods
        @prohibited_methods ||= MODULES.flat_map do |mod|
          mod.instance_methods.map(&:to_sym)
        end + RESERVED_METHOD_NAMES
      end
    end
  end
end
