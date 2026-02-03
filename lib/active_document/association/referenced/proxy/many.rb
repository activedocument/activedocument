# frozen_string_literal: true

module ActiveDocument
  module Association
    module Referenced
      module Proxy
        # Proxy for multi-document associations (belongs_to_many, has_many).
        # Extends the base Association::Many proxy with v2-specific behavior.
        class Many < Association::Many
          extend Forwardable

          def_delegators :criteria, :count
          def_delegators :_target, :first, :in_memory, :last, :pluck, :pluck_each, :reset, :uniq

          # Create a new collection proxy.
          #
          # @param base [ActiveDocument::Document] The owning document
          # @param target [Array, Criteria] The related documents
          # @param association [Association] The association metadata
          def initialize(base, target, association)
            enum = build_enumerable(target, base, association)
            super(base, enum, association) do
              raise_mixed if klass.embedded? && !klass.cyclic?
            end
          end

          # Append documents to the association.
          #
          # @param args [Array<ActiveDocument::Document>] Documents to append
          # @return [self] The proxy
          def <<(*args)
            docs = args.flatten
            return concat(docs) if docs.size > 1

            if (doc = docs.first)
              append(doc)
              doc.save if persistable? && !_assigning? && !doc.validated?
            end
            self
          end

          alias_method :push, :<<

          # Append multiple documents efficiently.
          #
          # @param documents [Array<ActiveDocument::Document>] Documents to append
          # @return [self] The proxy
          def concat(documents)
            docs = []
            inserts = []
            documents.each do |doc|
              next unless doc

              append(doc)
              save_or_delay(doc, docs, inserts) if persistable?
            end

            persist_delayed(docs, inserts)
            self
          end

          # Build a new document without saving.
          #
          # @param attributes [Hash] The attributes for the new document
          # @param type [Class] Optional subclass to build
          # @return [ActiveDocument::Document] The new document
          def build(attributes = {}, type = nil)
            doc = Factory.execute_build(type || klass, attributes, execute_callbacks: false)
            append(doc)
            doc.apply_post_processed_defaults
            yield(doc) if block_given?
            doc.run_pending_callbacks
            doc.run_callbacks(:build) { doc }
            doc
          end

          alias_method :new, :build

          # Delete a document from the association.
          #
          # @param document [ActiveDocument::Document] The document to remove
          # @return [ActiveDocument::Document] The removed document
          def delete(document)
            execute_callbacks_around(:remove, document) do
              result = _target.delete(document) do |doc|
                if doc
                  unbind_one(doc)
                  cascade!(doc) unless _assigning?
                end
              end

              reset_unloaded
              result
            end
          end

          alias_method :delete_one, :delete

          # Delete all documents optionally matching conditions.
          #
          # @param conditions [Hash] Optional conditions
          # @return [Integer] Number deleted
          def delete_all(conditions = nil)
            remove_all(conditions, :delete_all)
          end

          # Destroy all documents optionally matching conditions.
          #
          # @param conditions [Hash] Optional conditions
          # @return [Integer] Number destroyed
          def destroy_all(conditions = nil)
            remove_all(conditions, :destroy_all)
          end

          # Iterate over documents.
          #
          # @yield [ActiveDocument::Document] Each document
          # @return [Enumerator, Array] Enumerator or loaded documents
          def each(&block)
            if block
              _target.each(&block)
            else
              to_enum
            end
          end

          # Check if documents exist in the database.
          #
          # @param id_or_conditions [Object] ID, conditions, or :none
          # @return [Boolean]
          def exists?(id_or_conditions = :none)
            criteria.exists?(id_or_conditions)
          end

          # Find documents by ID or conditions.
          #
          # @param args [Array] IDs or conditions
          # @return [ActiveDocument::Document, Array<ActiveDocument::Document>]
          def find(*args, &block)
            matching = criteria.find(*args, &block)
            Array(matching).each { |doc| _target.push(doc) }
            matching
          end

          # Remove all associations without deleting.
          def nullify
            criteria.update_all(_association.foreign_key => nil)
            _target.clear do |doc|
              unbind_one(doc)
              doc.changed_attributes.delete(_association.foreign_key)
            end
          end

          alias_method :nullify_all, :nullify

          # Clear the association, deleting if destructive.
          #
          # @return [self] The proxy
          def purge
            return nullify unless _association.destructive?

            after_remove_error = nil
            criteria.delete_all
            many = _target.clear do |doc|
              execute_callback :before_remove, doc
              unbind_one(doc)
              doc.destroyed = true
              begin
                execute_callback :after_remove, doc
              rescue StandardError => e
                after_remove_error = e
              end
            end

            raise after_remove_error if after_remove_error

            many
          end

          alias_method :clear, :purge

          # Replace all documents.
          #
          # @param replacement [Array<ActiveDocument::Document>] The new documents
          # @return [self] The proxy
          def substitute(replacement)
            if replacement
              new_docs = replacement.compact

              if belongs_to_many?
                substitute_belongs_to_many(new_docs)
              else
                substitute_has_many(new_docs)
              end
            else
              purge
            end
            self
          end

          # Get unscoped criteria.
          #
          # @return [ActiveDocument::Criteria]
          def unscoped
            klass.unscoped.where(_association.foreign_key => _base.send(_association.primary_key))
          end

          private

          # Build the appropriate enumerable wrapper.
          #
          # @param target [Array, Criteria] The target
          # @param base [ActiveDocument::Document] The base document
          # @param association [Association] The association
          # @return [HasMany::Enumerable] The enumerable
          def build_enumerable(target, base, association)
            # Use the existing HasMany::Enumerable for consistency
            ActiveDocument::Association::Referenced::HasMany::Enumerable.new(target, base, association)
          end

          # Append a document to the target.
          #
          # @param document [ActiveDocument::Document] The document to append
          def append(document)
            with_add_callbacks(document, already_related?(document)) do
              _target.push(document)
              characterize_one(document)
              bind_one(document)
            end
          end

          # Execute add callbacks unless already related.
          #
          # @param document [ActiveDocument::Document] The document
          # @param already_related [Boolean] Whether already related
          def with_add_callbacks(document, already_related)
            execute_callback :before_add, document unless already_related
            yield
            execute_callback :after_add, document unless already_related
          end

          # Check if document is already related.
          #
          # @param document [ActiveDocument::Document] The document
          # @return [Boolean]
          def already_related?(document)
            document.persisted? &&
              document._association &&
              document.respond_to?(document._association.foreign_key) &&
              document.__send__(document._association.foreign_key) == _base._id
          end

          # Get the binding instance.
          #
          # @return [Binding::Base] The binding
          def binding
            @binding ||= _association.binder_class.new(_base, _target, _association)
          end

          # Get the collection.
          #
          # @return [Mongo::Collection] The collection
          def collection
            klass.collection
          end

          # Get the criteria for querying.
          #
          # @return [ActiveDocument::Criteria] The criteria
          def criteria
            @criteria ||= _association.criteria(_base)
          end

          # Cascade delete/destroy operations.
          #
          # @param document [ActiveDocument::Document] The document
          def cascade!(document)
            return unless persistable?

            case _association.dependent
            when :delete_all
              document.delete
            when :destroy
              document.destroy
            else
              document.save
            end
          end

          # Methods that should never be delegated to target
          NON_DELEGATED_METHODS = %i[class is_a? kind_of? instance_of?].freeze

          # Delegate unknown methods to target or criteria.
          def method_missing(name, ...)
            return super if NON_DELEGATED_METHODS.include?(name)

            if _target.respond_to?(name)
              _target.send(name, ...)
            else
              klass.send(:with_scope, criteria) do
                criteria.public_send(name, ...)
              end
            end
          end

          # Check if method can be handled.
          #
          # @param name [Symbol] Method name
          # @param _include_private [Boolean] Include private methods
          # @return [Boolean]
          def respond_to_missing?(name, _include_private = false)
            return false if NON_DELEGATED_METHODS.include?(name)

            _target.respond_to?(name) || criteria.respond_to?(name)
          end

          # Persist delayed inserts.
          #
          # @param docs [Array<ActiveDocument::Document>] Documents to persist
          # @param inserts [Array<Hash>] Raw insert documents
          def persist_delayed(docs, inserts)
            return if docs.empty?

            collection.insert_many(inserts, session: _session)
            docs.each do |doc|
              doc.new_record = false
              doc.run_after_callbacks(:create, :save) unless _association.autosave?
              doc.post_persist
            end
          end

          # Whether the association can be persisted.
          #
          # @return [Boolean]
          def persistable?
            !_binding? && (_creating? || (_base.persisted? && !_building?))
          end

          # Remove documents matching conditions.
          #
          # @param conditions [Hash] Conditions
          # @param method [Symbol] :delete_all or :destroy_all
          # @return [Integer] Number removed
          def remove_all(conditions = nil, method = :delete_all)
            selector = conditions || {}
            removed = klass.send(method, selector.merge!(criteria.selector))
            _target.delete_if do |doc|
              doc._matches?(selector).tap do |b|
                unbind_one(doc) if b
              end
            end
            removed
          end

          # Remove documents not in the given IDs.
          #
          # @param ids [Array<Object>] IDs to keep
          def remove_not_in(ids)
            removed = criteria.not_in(_id: ids)
            update_or_delete_all(removed)

            in_memory.each do |doc|
              next if ids.include?(doc._id)

              unbind_one(doc)
              _target.delete(doc)
              doc.destroyed = true if _association.destructive?
            end
          end

          # Update or delete removed documents.
          #
          # @param removed [ActiveDocument::Criteria] Documents to remove
          def update_or_delete_all(removed)
            if _association.destructive?
              removed.delete_all
            else
              removed.update_all(_association.foreign_key => nil)
            end
          end

          # Save or delay a document for batch insert.
          #
          # @param doc [ActiveDocument::Document] The document
          # @param docs [Array] Documents array
          # @param inserts [Array] Inserts array
          def save_or_delay(doc, docs, inserts)
            if doc.new_record? && doc.valid?(:create)
              doc.run_before_callbacks(:save, :create)
              docs.push(doc)
              inserts.push(doc.send(:as_attributes))
            else
              doc.save
            end
          end

          def _session
            _base.send(:_session)
          end

          # Check if this is a belongs_to_many association.
          #
          # @return [Boolean]
          def belongs_to_many?
            _association.association_type == :belongs_to_many
          end

          # Substitute for has_many associations.
          # FK is on the target side, so we need to update target documents.
          #
          # @param new_docs [Array<ActiveDocument::Document>] The new documents
          def substitute_has_many(new_docs)
            docs = []
            new_ids = new_docs.map(&:_id)
            remove_not_in(new_ids)
            new_docs.each do |doc|
              docs.push(doc) if doc.send(_association.foreign_key) != _base.send(_association.primary_key)
            end
            concat(docs)
          end

          # Substitute for belongs_to_many associations.
          # FK is on our side as an array, so we just need to update _base's FK array.
          # When base is persisted, documents should be auto-saved for FK sync.
          #
          # @param new_docs [Array<ActiveDocument::Document>] The new documents
          def substitute_belongs_to_many(new_docs)
            # Remember old docs to save after unbinding
            old_docs = in_memory.dup

            # Unbind current documents (removes base's ID from their inverse FK arrays)
            old_docs.each { |doc| unbind_one(doc) }
            _target.clear

            # Bind new documents
            new_docs.each { |doc| append(doc) }

            # Auto-save documents if base is persisted
            if _base.persisted? && !_building?
              # Save base to persist its FK array change
              _base.save if _base.changed?

              # Save old docs to persist the removal of base's ID from their inverse FK
              old_docs.each do |doc|
                doc.save if doc.persisted? && doc.changed?
              end
              # Save new docs to persist the addition of base's ID to their inverse FK
              new_docs.each do |doc|
                doc.save if doc.new_record? || doc.changed?
              end
            end
          end

          class << self
            # Get the eager loader.
            #
            # @param association [Association] The association
            # @param docs [Array<ActiveDocument::Document>] The documents
            # @return [Eager::Base] The eager loader
            def eager_loader(association, docs)
              association.eager_loader_class.new(association, docs)
            end

            # Whether embedded.
            #
            # @return [false] Always false
            def embedded?
              false
            end
          end
        end
      end
    end
  end
end
