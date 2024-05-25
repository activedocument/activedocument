# frozen_string_literal: true

require 'active_document/association/accessors'
require 'active_document/association/builders'
require 'active_document/association/bindable'
require 'active_document/association/depending'
require 'active_document/association/proxy'

require 'active_document/association/many'
require 'active_document/association/one'
require 'active_document/association/relatable'
require 'active_document/association/nested'
require 'active_document/association/referenced'
require 'active_document/association/embedded'
require 'active_document/association/macros'

require 'active_document/association/reflections'
require 'active_document/association/eager_loadable'

module ActiveDocument

  # Mixin module which adds association behavior to a ActiveDocument document.
  # Adds methods such as #embedded? which indicate a document's
  # relative association state.
  module Association
    extend ActiveSupport::Concern
    include Embedded::Cyclic
    include Referenced::AutoSave
    include Referenced::CounterCache
    include Referenced::Syncable
    include Accessors
    include Depending
    include Builders
    include Macros
    include Reflections

    # Map the macros to their corresponding Association classes.
    #
    # @return [ Hash ] The mapping from macros to their Association class.
    MACRO_MAPPING = {
      embeds_one: Association::Embedded::EmbedsOne,
      embeds_many: Association::Embedded::EmbedsMany,
      embedded_in: Association::Embedded::EmbeddedIn,
      has_one: Association::Referenced::HasOne,
      has_many: Association::Referenced::HasMany,
      has_and_belongs_to_many: Association::Referenced::HasAndBelongsToMany,
      belongs_to: Association::Referenced::BelongsTo
    }.freeze

    attr_accessor :_association

    included do
      class_attribute :polymorphic
      self.polymorphic = false
    end

    # Determine if the document itself is embedded in another document via the
    # proper channels. (If it has a parent document.)
    #
    # @example Is the document embedded?
    #   address.embedded?
    #
    # @return [ true | false ] True if the document has a parent document.
    def embedded?
      @embedded ||= (cyclic ? _parent.present? : self.class.embedded?)
    end

    # Determine if the document is part of an embeds_many association.
    #
    # @example Is the document in an embeds many?
    #   address.embedded_many?
    #
    # @return [ true | false ] True if in an embeds many.
    def embedded_many?
      _association&.is_a?(Association::Embedded::EmbedsMany)
    end

    # Determine if the document is part of an embeds_one association.
    #
    # @example Is the document in an embeds one?
    #   address.embedded_one?
    #
    # @return [ true | false ] True if in an embeds one.
    def embedded_one?
      _association&.is_a?(Association::Embedded::EmbedsOne)
    end

    # Get the association name for this document. If no association was defined
    #   an error will be raised.
    #
    # @example Get the association name.
    #   document.association_name
    #
    # @raise [ Errors::NoMetadata ] If no association metadata is present.
    #
    # @return [ Symbol ] The association name.
    def association_name
      raise Errors::NoMetadata.new(self.class.name) unless _association

      _association.name
    end

    # Determine if the document is part of an references_many association.
    #
    # @example Is the document in a references many?
    #   post.referenced_many?
    #
    # @return [ true | false ] True if in a references many.
    def referenced_many?
      _association&.is_a?(Association::Referenced::HasMany)
    end

    # Determine if the document is part of an references_one association.
    #
    # @example Is the document in a references one?
    #   address.referenced_one?
    #
    # @return [ true | false ] True if in a references one.
    def referenced_one?
      _association&.is_a?(Association::Referenced::HasOne)
    end

    # Convenience method for iterating through the loaded associations and
    # reloading them.
    #
    # @example Reload the associations.
    #   document.reload_relations
    #
    # @return [ Hash ] The association metadata.
    def reload_relations
      relations.each_pair do |name, _meta|
        next unless instance_variable_defined?(:"@_#{name}") &&
                    (_parent.nil? || instance_variable_get(:"@_#{name}") != _parent)

        remove_instance_variable(:"@_#{name}")
      end
    end
  end
end