# frozen_string_literal: true

module ActiveDocument
  module Association
    module Referenced
      module V2
        module Eager
          # Base class for eager loading strategies.
          # Subclasses implement specific eager loading patterns.
          class Base
            attr_reader :association, :docs

            # @param association [Association] The association to eager load
            # @param docs [Array<ActiveDocument::Document>] The documents to preload
            def initialize(association, docs)
              @association = association
              @docs = docs
              @grouped_docs = {}
            end

            # Run the eager loader.
            #
            # @return [Array] The loaded documents
            def run
              preload
              docs.map { |d| d.send(association.name) if d.respond_to?(association.name) }
            end

            protected

            # Preload the association into documents.
            # Must be implemented by subclasses.
            def preload
              raise NotImplementedError, "#{self.class} must implement #preload"
            end

            # Set a preloaded document/array on the parent.
            #
            # @param id [Object] The parent's ID
            # @param element [Document, Array] The preloaded element(s)
            def set_on_parent(id, element)
              grouped_docs[id]&.each do |d|
                set_relation(d, element)
              end
            end

            # Get documents grouped by the grouping key.
            #
            # @return [Hash] Documents grouped by key
            def grouped_docs
              @grouped_docs[association.name] ||= docs.group_by do |doc|
                doc.send(group_by_key) if doc.respond_to?(group_by_key)
              end.reject { |k, _| k.nil? }
            end

            # Get the unique keys from documents.
            #
            # @return [Array] The keys
            def keys_from_docs
              grouped_docs.keys
            end

            # The key to group documents by.
            # Must be implemented by subclasses.
            #
            # @return [Symbol, String] The grouping key
            def group_by_key
              raise NotImplementedError, "#{self.class} must implement #group_by_key"
            end

            # The key to look up in loaded documents.
            # Must be implemented by subclasses.
            #
            # @return [Symbol, String] The lookup key
            def key
              raise NotImplementedError, "#{self.class} must implement #key"
            end

            # Set the association on a document.
            #
            # @param doc [ActiveDocument::Document] The document
            # @param element [Document, Array] The element to set
            def set_relation(doc, element)
              doc.set_relation(association.name, element) if doc.present?
            end

            # Iterate over loaded documents from the database.
            #
            # @yield [ActiveDocument::Document] Each loaded document
            def each_loaded_document(&block)
              return if keys_from_docs.empty?

              criteria = association.relation_class.criteria
              criteria = criteria.apply_scope(association.scope)
              criteria = criteria.any_in(key => keys_from_docs)
              criteria.inclusions = criteria.inclusions - [association]
              criteria.each(&block)
            end
          end
        end
      end
    end
  end
end
