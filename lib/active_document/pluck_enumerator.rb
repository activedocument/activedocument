# frozen_string_literal: true

module ActiveDocument

  # Utility class to add enumerable behavior for Criteria#pluck_each.
  # Also provides class methods for pluck-related operations used by
  # other components (e.g., HasMany::Enumerable).
  #
  # @api private
  class PluckEnumerator
    include Enumerable

    class << self
      # Prepares the field names for plucking by normalizing them to their
      # database field names. Also prepares a projection hash if requested.
      #
      # @param [ Class ] document_class The document class to use for normalization.
      # @param [ Array<String | Symbol> ] field_names The field names to pluck.
      # @param [ Boolean ] prepare_projection Whether to prepare a projection hash.
      #
      # @return [ Hash ] A hash containing :field_names and :projection keys.
      def prepare_pluck(document_class, field_names, prepare_projection: false)
        normalized_field_names = []
        projection = {}

        field_names.each do |field|
          db_fn = document_class.database_field_name(field)
          normalized_field_names.push(db_fn)

          next unless prepare_projection

          cleaned_name = document_class.cleanse_localized_field_names(field)
          canonical_name = document_class.database_field_name(cleaned_name)
          projection[canonical_name] = true
        end

        { field_names: normalized_field_names, projection: projection }
      end

      # Plucks the given field names from the given documents.
      #
      # @param [ Class ] document_class The document class to use for demongoization.
      # @param [ Array<Hash> ] documents The documents to pluck from.
      # @param [ Array<String> ] field_names The normalized field names.
      #
      # @return [ Array ] The plucked values.
      def pluck_from_documents(document_class, documents, field_names)
        documents.map do |doc|
          values = field_names.map { |name| extract_value(document_class, doc, name.to_s) }
          values.size == 1 ? values.first : values
        end
      end

      # Extracts the value for the given field name from the given attribute
      # hash.
      #
      # @param [ Class ] document_class The document class to use.
      # @param [ Hash ] attrs The attributes hash.
      # @param [ String ] field_name The name of the field to extract.
      #
      # @return [ Object ] The value for the given field name
      def extract_value(document_class, attrs, field_name)
        idx = 1
        num_meths = field_name.count('.') + 1
        curr = attrs.dup

        document_class.traverse_association_tree(field_name) do |meth, obj, is_field|
          field = obj if is_field

          # use the correct document class to check for localized fields on
          # embedded documents.
          document_class = obj.klass if obj.respond_to?(:klass)

          is_translation = false
          # If no association or field was found, check if the meth is an
          # _translations field.
          if obj.nil? && (trans = meth.match(/(.*)_translations\z/)&.captures&.first)
            is_translation = true
            meth = document_class.database_field_name(trans)
          end

          curr = descend(idx, curr, meth, field, num_meths, is_translation)

          idx += 1
        end
        curr
      end

      private

      # Fetch the element from the given hash and demongoize it using the
      # given field. If the obj is an array, map over it and call this method
      # on all of its elements.
      #
      # @param [ Hash | Array<Hash> ] obj The hash or array of hashes to fetch from.
      # @param [ String ] key The key to fetch from the hash.
      # @param [ Field ] field The field to use for demongoization.
      #
      # @return [ Object ] The demongoized value.
      def fetch_and_demongoize(obj, key, field)
        if obj.is_a?(Array)
          obj.map { |doc| fetch_and_demongoize(doc, key, field) }
        else
          value = obj.try(:fetch, key, nil)
          field ? field.demongoize(value) : value.class.demongoize(value)
        end
      end

      # Descend one level in the attribute hash.
      #
      # @param [ Integer ] part The current part index.
      # @param [ Hash | Array<Hash> ] current The current level in the attribute hash.
      # @param [ String ] method_name The method name to descend to.
      # @param [ Field | nil ] field The field to use for demongoization.
      # @param [ Integer ] part_count The total number of parts in the field name.
      # @param [ Boolean ] is_translation Whether the method is an _translations field.
      #
      # @return [ Object ] The value at the next level.
      def descend(part, current, method_name, field, part_count, is_translation)
        # 1. If curr is an array fetch from all elements in the array.
        # 2. If the field is localized, and is not an _translations field
        #    (_translations fields don't show up in the fields hash).
        #    - If this is the end of the methods, return the translation for
        #      the current locale.
        #    - Otherwise, return the whole translations hash so the next method
        #      can select the language it wants.
        # 3. If the meth is an _translations field, do not demongoize the
        #    value so the full hash is returned.
        # 4. Otherwise, fetch and demongoize the value for the key meth.
        if current.is_a? Array
          res = fetch_and_demongoize(current, method_name, field)
          res.empty? ? nil : res
        elsif !is_translation && field&.localized?
          if part < part_count
            current.try(:fetch, method_name, nil)
          else
            fetch_and_demongoize(current, method_name, field)
          end
        elsif is_translation
          current.try(:fetch, method_name, nil)
        else
          fetch_and_demongoize(current, method_name, field)
        end
      end
    end

    # Create the new PluckEnumerator.
    #
    # @api private
    #
    # @example Initialize a PluckEnumerator.
    #   PluckEnumerator.new(klass, view, fields)
    #
    # @param [ Class ] klass The base of the binding.
    # @param [ Mongo::Collection::View ] view The Mongo view context.
    # @param [ String | Symbol ] *fields Field(s) to pluck,
    #   which may include nested fields using dot-notation.
    def initialize(klass, view, fields)
      @klass = klass
      @view = view
      @fields = fields
    end

    # Iterate through plucked field value(s) from the database
    # for the view context. Yields result values progressively as
    # they are read from the database. The yielded results are
    # normalized according to their ActiveDocument field types.
    #
    # @api private
    #
    # @example Iterate through the plucked values from the database.
    #   context.pluck_each(:name) { |name| puts name }
    #
    # @param [ Proc ] &block The block to call once for each plucked
    #   result.
    #
    # @return [ Enumerator | PluckEnumerator ] The enumerator, or
    #   self if a block was given.
    def each(&block)
      return to_enum unless block

      prep = self.class.prepare_pluck(@klass, @fields, prepare_projection: true)
      @view.projection(prep[:projection]).each do |doc|
        yield_result(doc, prep[:field_names], &block)
      end

      self
    end

    private

    def yield_result(doc, field_names)
      values = field_names.map { |name| self.class.extract_value(@klass, doc, name) }
      yield(values.size == 1 ? values.first : values)
    end
  end
end
