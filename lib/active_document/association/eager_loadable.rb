# frozen_string_literal: true

require 'active_document/association/eager'

module ActiveDocument
  module Association

    # This module defines the eager loading behavior for criteria.
    module EagerLoadable

      # Indicates whether the criteria has association
      # inclusions which should be eager loaded.
      #
      # @return [ true | false ] Whether to eager load.
      def eager_loadable?
        !criteria.inclusions.empty?
      end

      # Load the associations for the given documents.
      #
      # @param [ Array<ActiveDocument::Document> ] docs The documents.
      #
      # @return [ Array<ActiveDocument::Document> ] The given documents.
      def eager_load(docs)
        docs.tap do |d|
          if eager_loadable?
            preload(criteria.inclusions, d)
          end
        end
      end

      # Load the associations for the given documents. This will be done
      # recursively to load the associations of the given documents'
      # associated documents.
      #
      # @param [ Array<ActiveDocument::Association::Relatable> ] associations
      #   The associations to load.
      # @param [ Array<ActiveDocument::Document> ] docs The documents.
      def preload(associations, docs)
        assoc_map = associations.group_by(&:inverse_class_name)
        docs_map = {}
        queue = [klass.to_s]

        # account for single-collection inheritance
        queue.push(klass.root_class.to_s) if klass != klass.root_class

        while (klass = queue.shift)
          next unless (as = assoc_map.delete(klass))

          as.each do |assoc|
            queue << assoc.class_name

            # If this class is nested in the inclusion tree, only load documents
            # for the association above it. If there is no parent association,
            # we will include documents from the documents passed to this method.
            ds = docs
            unless assoc.parent_inclusions.empty?
              ds = assoc.parent_inclusions.map { |p| docs_map[p].to_a }.flatten
            end

            res = assoc.relation.eager_loader([assoc], ds).run

            docs_map[assoc.name] ||= [].to_set
            docs_map[assoc.name].merge(res)
          end
        end
      end
    end
  end
end
