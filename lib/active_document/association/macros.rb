# frozen_string_literal: true

module ActiveDocument
  module Association
    # This module contains the core macros for defining associations between
    # documents. They can be either embedded or referenced.
    module Macros
      extend ActiveSupport::Concern

      included do
        class_attribute :embedded, instance_reader: false
        class_attribute :embedded_relations
        class_attribute :relations

        # A hash that maps aliases to their associations. This hash maps the
        # associations "in database name" to its "in code" name. This is used when
        # associations specify the `store_as` option, or on a referenced association.
        # On a referenced association, this is used to map the foreign key to
        # the association's name. For example, if we had the following
        # relationship:
        #
        #   User has_many Accounts
        #
        # User will have an entry in the aliased associations hash:
        #
        #   account_ids => accounts
        #
        # Note that on the belongs_to associations, the mapping from
        # foreign key => name is not in the aliased_associations hash, but a
        # mapping from name => foreign key is in the aliased_fields hash.
        #
        # @return [ Hash<String, String> ] The aliased associations hash.
        #
        # @api private
        class_attribute :aliased_associations

        # @return [ Set<String> ] The set of associations that are configured
        #   with :store_as parameter.
        class_attribute :stored_as_associations

        self.embedded = false
        self.embedded_relations = BSON::Document.new
        self.relations = BSON::Document.new
        self.aliased_associations = {}
        self.stored_as_associations = Set.new
      end

      # This is convenience for libraries still on the old API.
      #
      # @example Get the associations.
      #   person.associations
      #
      # @return [ Hash ] The associations.
      def associations
        relations
      end

      # Class methods for associations.
      module ClassMethods
        # Adds the association back to the parent document. This macro is
        # necessary to set the references from the child back to the parent
        # document. If a child does not define this association calling
        # persistence methods on the child object will cause a save to fail.
        #
        # @example Define the association.
        #
        #   class Person
        #     include ActiveDocument::Document
        #     embeds_many :addresses
        #   end
        #
        #   class Address
        #     include ActiveDocument::Document
        #     embedded_in :person
        #   end
        #
        # @param [ Symbol ] name The name of the association.
        # @param [ Hash ] options The association options.
        # @param &block Optional block for defining extensions.
        def embedded_in(name, options = {}, &block)
          define_association!(__method__, name, options, &block)
        end

        # Adds the association from a parent document to its children. The name
        # of the association needs to be a pluralized form of the child class
        # name.
        #
        # @example Define the association.
        #
        #   class Person
        #     include ActiveDocument::Document
        #     embeds_many :addresses
        #   end
        #
        #   class Address
        #     include ActiveDocument::Document
        #     embedded_in :person
        #   end
        #
        # @param [ Symbol ] name The name of the association.
        # @param [ Hash ] options The association options.
        # @param &block Optional block for defining extensions.
        def embeds_many(name, options = {}, &block)
          define_association!(__method__, name, options, &block)
        end

        # Adds the association from a parent document to its child. The name
        # of the association needs to be a singular form of the child class
        # name.
        #
        # @example Define the association.
        #
        #   class Person
        #     include ActiveDocument::Document
        #     embeds_one :name
        #   end
        #
        #   class Name
        #     include ActiveDocument::Document
        #     embedded_in :person
        #   end
        #
        # @param [ Symbol ] name The name of the association.
        # @param [ Hash ] options The association options.
        # @param &block Optional block for defining extensions.
        def embeds_one(name, options = {}, &block)
          define_association!(__method__, name, options, &block)
        end

        # Adds a referenced association from the child Document to a single Document
        # in another database or collection. The foreign key is stored on this document.
        #
        # @example Define the association.
        #
        #   class Game
        #     include ActiveDocument::Document
        #     belongs_to_one :person
        #   end
        #
        #   class Person
        #     include ActiveDocument::Document
        #     has_one :game
        #   end
        #
        # @param [ Symbol ] name The name of the association.
        # @param [ Hash ] options The association options.
        # @param &block Optional block for defining extensions.
        def belongs_to_one(name, options = {}, &block)
          define_referenced_association!(name, :belongs_to_one, options, &block)
        end

        # Alias for backwards compatibility.
        alias_method :belongs_to, :belongs_to_one

        # Adds a referenced association from the child Document to multiple Documents
        # in another database or collection. The foreign key array is stored on this document.
        #
        # This replaces has_and_belongs_to_many with clearer semantics about where
        # the foreign keys are stored.
        #
        # @example Define the association.
        #
        #   class Person
        #     include ActiveDocument::Document
        #     belongs_to_many :preferences
        #   end
        #
        #   class Preference
        #     include ActiveDocument::Document
        #     has_many :people, inverse_of: :preferences
        #   end
        #
        # @param [ Symbol ] name The name of the association.
        # @param [ Hash ] options The association options.
        # @param &block Optional block for defining extensions.
        def belongs_to_many(name, options = {}, &block)
          define_referenced_association!(name, :belongs_to_many, options, &block)
        end

        # Adds a referenced association from a parent Document to many
        # Documents in another database or collection. The foreign key is
        # stored on the target documents.
        #
        # @example Define the association.
        #
        #   class Person
        #     include ActiveDocument::Document
        #     has_many :posts
        #   end
        #
        #   class Post
        #     include ActiveDocument::Document
        #     belongs_to_one :person
        #   end
        #
        # @param [ Symbol ] name The name of the association.
        # @param [ Hash ] options The association options.
        # @param &block Optional block for defining extensions.
        def has_many(name, options = {}, &block)
          define_referenced_association!(name, :has_many, options, &block)
        end

        # Adds a referenced many-to-many association between many of this
        # Document and many of another Document.
        #
        # @deprecated Use {#belongs_to_many} instead. This method will be removed
        #   in a future version.
        #
        # @example Define the association.
        #
        #   class Person
        #     include ActiveDocument::Document
        #     has_and_belongs_to_many :preferences
        #   end
        #
        #   class Preference
        #     include ActiveDocument::Document
        #     has_and_belongs_to_many :people
        #   end
        #
        # @param [ Symbol ] name The name of the association.
        # @param [ Hash ] options The association options.
        # @param &block Optional block for defining extensions.
        def has_and_belongs_to_many(name, options = {}, &block)
          ActiveDocument.logger&.warn(
            "DEPRECATION WARNING: has_and_belongs_to_many is deprecated. Use belongs_to_many instead. " \
            "(called from #{caller_locations(1, 1).first})"
          )
          belongs_to_many(name, options, &block)
        end

        # Adds a referenced association from a parent Document to a single
        # Document in another database or collection. The foreign key is
        # stored on the target document.
        #
        # @example Define the association.
        #
        #   class Person
        #     include ActiveDocument::Document
        #     has_one :game
        #   end
        #
        #   class Game
        #     include ActiveDocument::Document
        #     belongs_to_one :person
        #   end
        #
        # @param [ Symbol ] name The name of the association.
        # @param [ Hash ] options The association options.
        # @param &block Optional block for defining extensions.
        def has_one(name, options = {}, &block)
          define_referenced_association!(name, :has_one, options, &block)
        end

        private

        def define_association!(macro_name, name, options = {}, &block)
          Association::MACRO_MAPPING[macro_name].new(self, name, options, &block).tap do |assoc|
            assoc.setup!
            self.relations = relations.merge(name => assoc)
            if assoc.embedded? && assoc.respond_to?(:store_as) && assoc.store_as != name
              aliased_associations[assoc.store_as] = name
              stored_as_associations << assoc.store_as
            end
          end
        end

        def define_referenced_association!(name, type, options = {}, &block)
          Referenced::Association.new(self, name, type, options, &block).tap do |assoc|
            assoc.setup!
            self.relations = relations.merge(name.to_s => assoc)
          end
        end
      end
    end
  end
end
