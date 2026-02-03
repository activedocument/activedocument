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
          #
          # @raise [Errors::InverseRelationAssignmentDisallowed] If assigning from inverse side
          #   when allow_inverse_relation_assignment is false
          def <<(*args)
            check_inverse_assignment_allowed!
            docs = args.flatten
            return concat(docs) if docs.size > 1

            if (doc = docs.first)
              append(doc)
              # FK is set in memory; user must save doc to persist
            end
            unsynced_base
            self
          end

          alias_method :push, :<<

          # Append multiple documents efficiently.
          #
          # @param documents [Array<ActiveDocument::Document>] Documents to append
          # @return [self] The proxy
          #
          # @raise [Errors::InverseRelationAssignmentDisallowed] If assigning from inverse side
          #   when allow_inverse_relation_assignment is false
          def concat(documents)
            check_inverse_assignment_allowed!
            docs = []
            inserts = []
            ids = []
            documents.each do |doc|
              next unless doc

              # Don't persist base FK individually - we'll batch it below
              append(doc, persist_base: false)
              if persistable?
                # Only collect IDs for belongs_to_many where we need to update base's FK array
                ids << doc.public_send(_association.primary_key) if belongs_to_many?
                save_or_delay(doc, docs, inserts)
              end
            end

            # For belongs_to_many, batch persist base's FK array with $addToSet
            # Use add_to_set (not push) to avoid duplicates in the FK array
            if belongs_to_many? && (persistable? || _creating?) && ids.any? && _base.persisted?
              _base.add_to_set(_association.foreign_key => ids)
            end

            persist_delayed(docs, inserts)
            unsynced_base
            self
          end

          # Build a new document without saving.
          #
          # @param attributes [Hash] The attributes for the new document
          # @param type [Class] Optional subclass to build
          # @return [ActiveDocument::Document] The new document
          def build(attributes = {}, type = nil)
            doc = Factory.execute_build(type || klass, attributes, execute_callbacks: false)
            # For belongs_to_many: Apply defaults BEFORE appending so that custom _id
            # defaults are set before the ID is added to the FK array
            # For has_many: Apply defaults AFTER appending so that defaults can
            # access the parent via the association
            doc.apply_post_processed_defaults if belongs_to_many?
            append(doc)
            doc.apply_post_processed_defaults unless belongs_to_many?
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
                  # For belongs_to_many, persist FK changes to the database
                  persist_delete_fk(doc) if belongs_to_many? && _base.persisted?
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
          #
          # @param replacement [Array, nil] Optional documents to keep associated
          def nullify(replacement = nil)
            replacement_ids = replacement&.map { |doc| doc.send(_association.primary_key) }&.to_set
            docs_to_remove = replacement_ids ? in_memory.reject { |doc| replacement_ids.include?(doc.send(_association.primary_key)) } : in_memory.dup

            # Run before_remove callbacks first - if any raise, abort without clearing
            docs_to_remove.each { |doc| execute_callback :before_remove, doc }

            # Now do the actual FK clearing
            if belongs_to_many?
              # For belongs_to_many, remove base's primary key value from target's inverse FK array
              # and clear/update base's FK array
              if _association.inverse_foreign_key
                if replacement_ids
                  # Only pull from docs being removed
                  docs_to_remove.each do |doc|
                    doc.pull(_association.inverse_foreign_key => base_pk_value) if doc.persisted?
                  end
                else
                  criteria.pull(_association.inverse_foreign_key => base_pk_value)
                end
              end
              if replacement_ids
                # Keep replacement docs' IDs in base FK array
                new_ids = replacement.map { |doc| doc.send(_association.primary_key) }
                _base.send(_association.foreign_key_setter, new_ids)
                _base.set(_association.foreign_key => new_ids) if _base.persisted?
              else
                _base.send(_association.foreign_key_setter, [])
                _base.set(_association.foreign_key => []) if _base.persisted?
              end
              # Reset the cached criteria and target's unloaded criteria since FK array changed
              @criteria = nil
            else
              # For has_many, set target's FK to nil
              if replacement_ids
                docs_to_remove.each do |doc|
                  doc.update_attribute(_association.foreign_key, nil) if doc.persisted?
                end
              else
                criteria.update_all(_association.foreign_key => nil)
              end
            end

            after_remove_error = nil
            if replacement_ids
              # Remove only the docs not in replacement
              docs_to_remove.each do |doc|
                _target.delete(doc)
                unbind_one(doc)
                doc.changed_attributes.delete(_association.foreign_key) unless belongs_to_many?
                begin
                  execute_callback :after_remove, doc
                rescue StandardError => e
                  after_remove_error = e
                end
              end
            else
              _target.clear do |doc|
                unbind_one(doc)
                doc.changed_attributes.delete(_association.foreign_key) unless belongs_to_many?
                begin
                  execute_callback :after_remove, doc
                rescue StandardError => e
                  after_remove_error = e
                end
              end
            end

            # Reset the enumerable's unloaded criteria to use the new criteria for BTM
            _target.reset_unloaded(criteria) if belongs_to_many? && _target.respond_to?(:reset_unloaded)

            raise after_remove_error if after_remove_error

            self
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
          #
          # @raise [Errors::InverseRelationAssignmentDisallowed] If assigning from inverse side
          #   when allow_inverse_relation_assignment is false
          def substitute(replacement)
            check_inverse_assignment_allowed!
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
            if belongs_to_many?
              # For belongs_to_many, FK is on base as array, query targets by primary key
              ids = _base.send(_association.foreign_key) || []
              klass.unscoped.where(_association.primary_key => { '$in' => ids })
            else
              # For has_many, FK is on target
              klass.unscoped.where(_association.foreign_key => _base.send(_association.primary_key))
            end
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
          # @param persist_base [Boolean] Whether to persist base FK immediately
          def append(document, persist_base: true)
            with_add_callbacks(document, already_related?(document)) do
              _target.push(document)
              characterize_one(document)
              bind_one(document)

              # For belongs_to_many, persist base's FK array atomically when
              # adding documents to the association (not during build operations)
              if persist_base && belongs_to_many? && persistable? && _base.persisted? && !_building?
                _base.add_to_set(_association.foreign_key => document.public_send(_association.primary_key))
              end

              # Reset cached criteria for belongs_to_many since FK array changed
              @criteria = nil if belongs_to_many?
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

          # Get the base's primary key value for inverse FK operations.
          # For belongs_to_many, this is the value stored in target's inverse FK array.
          #
          # @return [Object] The base's primary key value
          def base_pk_value
            if (pk = _association.options.inverse_primary_key)
              _base.send(pk)
            else
              _base._id
            end
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
            # No else - FK is set in memory; user must save to persist
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
            end
            # For existing docs, FK is set in memory; user must save to persist
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

          # Check if inverse relation assignment is allowed.
          # Raises error if assigning from has_* side when not allowed.
          #
          # @raise [Errors::InverseRelationAssignmentDisallowed] If not allowed
          def check_inverse_assignment_allowed!
            return if _association.stores_foreign_key? # belongs_to_* side - always OK
            return if _base.allow_inverse_relation_assignment?

            raise Errors::InverseRelationAssignmentDisallowed.new(
              _association.name,
              _base.class,
              _association.relation_class
            )
          end

          # Mark the base as unsynced with respect to the foreign key.
          # This allows the sync callbacks to run.
          #
          # @return [nil]
          def unsynced_base
            return unless belongs_to_many?

            _base._synced[_association.foreign_key] = false
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
            # Deduplicate documents by primary key to prevent duplicate IDs
            new_docs = new_docs.uniq { |doc| doc.send(_association.primary_key) }

            # Remember old docs to save after unbinding
            old_docs = in_memory.dup
            new_doc_ids = new_docs.map { |doc| doc.send(_association.primary_key) }.to_set

            # Find docs being removed (not in new_docs)
            docs_to_remove = old_docs.reject { |doc| new_doc_ids.include?(doc.send(_association.primary_key)) }

            # Remove base's ID from removed documents' inverse FK arrays
            if _base.persisted? && _association.inverse_foreign_key && docs_to_remove.any?
              docs_to_remove.each do |doc|
                doc.pull(_association.inverse_foreign_key => base_pk_value) if doc.persisted?
              end
            end

            # Unbind current documents (removes base's ID from their inverse FK arrays in memory)
            old_docs.each { |doc| unbind_one(doc) }
            _target.clear

            # Set the FK array on base to new IDs
            new_ids = new_docs.map { |doc| doc.send(_association.primary_key) }
            _base.send(_association.foreign_key_setter, new_ids)

            # Persist base's FK atomically when base is already persisted
            if _base.persisted?
              updates = { _association.foreign_key => new_ids }
              # Also update timestamps if the model has them
              updated_at_field = _base.class.database_field_name(:updated_at)
              if updated_at_field && _base.respond_to?(:updated_at=)
                now = Time.now
                _base.updated_at = now
                updates[updated_at_field] = now
              end
              _base.set(updates)
            end

            # Reset the cached criteria since FK array changed
            @criteria = nil
            # Reset the enumerable's unloaded criteria to use the new criteria
            _target.reset_unloaded(criteria) if _target.respond_to?(:reset_unloaded)

            # Bind new documents (without persisting since FK is handled by save)
            new_docs.each { |doc| append(doc, persist_base: false) }

            # FK changes are in memory; user must save related docs to persist
            # Base's FK array is already persisted via atomic $set above

            # Mark as unsynced so the sync callback can run when base is saved
            unsynced_base
          end

          # Persist the FK removal for belongs_to_many delete operations.
          # Uses atomic $pull to remove IDs from both sides.
          #
          # @param doc [ActiveDocument::Document] The deleted document
          def persist_delete_fk(doc)
            # Pull the document's ID from base's FK array
            _base.pull(_association.foreign_key => doc.public_send(_association.primary_key))

            # Pull base's primary key value from the document's inverse FK array
            if _association.inverse_foreign_key && doc.persisted?
              doc.pull(_association.inverse_foreign_key => base_pk_value)
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
