# frozen_string_literal: true

module ActiveDocument
  module Association
    module Referenced

      # Mixin module included into ActiveDocument::Document which adds
      # the ability to automatically save opposite-side documents
      # in referenced associations when saving the subject document.
      module AutoSave
        extend ActiveSupport::Concern

        # Used to prevent infinite loops in associated autosaves.
        #
        # @example Is the document autosaved?
        #   document.autosaved?
        #
        # @return [ true | false ] Has the document already been autosaved?
        def autosaved?
          Threaded.autosaved?(self)
        end

        # Begin the associated autosave.
        #
        # @example Begin autosave.
        #   document.__autosaving__
        def __autosaving__
          Threaded.begin_autosave(self)
          yield
        ensure
          Threaded.exit_autosave(self)
        end

        # Check if there is changes for auto-saving
        #
        # @example Return true if there is changes on self or in
        #           autosaved associations.
        #   document.changed_for_autosave?
        def changed_for_autosave?(doc)
          doc.new_record? || doc.changed? || doc.marked_for_destruction?
        end

        # Define the autosave method on an association's owning class for
        # an associated object.
        #
        # @example Define the autosave method:
        #   Association::Referenced::Autosave.define_autosave!(association)
        #
        # @param [ ActiveDocument::Association::Relatable ] association The association for which autosaving is enabled.
        #
        # @return [ Class ] The association's owner class.
        def self.define_autosave!(association)
          association.inverse_class.tap do |klass|
            save_method = :"autosave_documents_for_#{association.name}"
            # Use around callback so we can halt if associated documents fail to save
            assoc = association
            klass.send(:define_method, save_method) do |&block|
              if before_callback_halted?
                self.before_callback_halted = false
                block.call if block
              else
                # First, yield to actually persist this document
                block.call if block

                # Then try to save associated documents
                __autosaving__ do
                  if (assoc_value = ivar(assoc.name))
                    Array(assoc_value).each do |doc|
                      next unless changed_for_autosave?(doc)

                      pc = doc.persistence_context? ? doc.persistence_context : persistence_context.for_child(doc)
                      saved = doc.with(pc, &:save)
                      # If associated document failed to save and the association is required,
                      # delete this document to rollback.
                      # If the association is optional, the child can still be saved.
                      # Note: We can't use throw(:abort) in after callbacks
                      # See: https://github.com/rails/rails/issues/33192
                      if !saved && assoc.send(:require_association?)
                        delete if persisted?
                        self.new_record = true
                        self.before_callback_halted = true
                        break
                      end
                    end
                  end
                end
              end
            end
            klass.around_persist_parent save_method, unless: :autosaved?
          end
        end
      end
    end
  end
end
