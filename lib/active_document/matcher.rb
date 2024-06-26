# frozen_string_literal: true

module ActiveDocument

  # Utility module containing methods which assist in performing
  # in-memory matching of documents with MQL query expressions.
  #
  # @api private
  module Matcher

    extend self

    # Extracts field values in the document at the specified key.
    #
    # The document can be a Hash or a model instance.
    #
    # The key is a valid MongoDB dot notation key. The following use cases are
    # supported:
    #
    # - Simple field traversal (`foo`) - retrieves the field `foo` in the
    #   current document.
    # - Hash/embedded document field traversal (`foo.bar`) - retrieves the
    #   field `foo` in the current document, then retrieves the field `bar`
    #   from the value of `foo`. Each path segment could descend into an
    #   embedded document or a hash field.
    # - Array element retrieval (`foo.N`) - retrieves the Nth array element
    #   from the field `foo` which must be an array. N must be a non-negative
    #   integer.
    # - Array traversal (`foo.bar`) - if `foo` is an array field, and
    #   the elements of `foo` are hashes or embedded documents, this returns
    #   an array of values of the `bar` field in each of the hashes in the
    #   `foo` array.
    #
    # This method can return an individual field value in some document
    # or an array of values from multiple documents. The array can be returned
    # because a field value in the specified path is an array of primitive
    # values (e.g. integers) or because a field value in the specified path
    # is an array of documents (e.g. a one-to-many embedded association),
    # in which case the leaf value may be a scalar for each individual document.
    # If the leaf value is an array and a one-to-many association was traversed,
    # the return value will be an array of arrays. Note that an individual
    # field value can also be an array and this case is indistinguishable
    # from and behaves identically to association traversal for the purposes
    # of, for example, subsequent array element retrieval.
    #
    # @param [ ActiveDocument::Document | Hash ] document The document to extract from.
    # @param [ String ] key The key path to extract.
    #
    # @return [ Object | Array ] Field value or values.
    def extract_attribute(document, key)
      if document.respond_to?(:as_attributes, true)
        # If a document has hash fields, as_attributes would keep those fields
        # as Hash instances which do not offer indifferent access.
        # Convert to BSON::Document to get indifferent access on hash fields.
        document = document.send(:as_attributes)
      end

      current = [document]

      key.to_s.split('.').each do |field|
        new = []
        current.each do |doc|
          case doc
          when Hash
            actual_key = find_exact_key(doc, field)
            unless actual_key.nil?
              new << doc[actual_key]
            end
          when Array
            if (index = field.to_i).to_s == field && (doc.length > index)
              new << doc[index]
            end

            doc.each do |subdoc|
              next unless subdoc.is_a?(Hash)

              actual_key = find_exact_key(subdoc, field)
              unless actual_key.nil?
                new << subdoc[actual_key]
              end
            end
          end
        end
        current = new
        break if current.empty?
      end

      current
    end

    # Indifferent string or symbol key lookup, returning the exact key.
    #
    # @param [ Hash ] hash The input hash.
    # @param [ String | Symbol ] key The key to perform indifferent lookups with.
    #
    # @return [ String | Symbol | nil ] The exact key (with the correct type) that exists in the hash, or nil if the key does not exist.
    def find_exact_key(hash, key)
      key_s = key.to_s
      return key_s if hash.key?(key_s)

      key_sym = key.to_sym
      hash.key?(key_sym) ? key_sym : nil
    end
  end
end

require 'active_document/matcher/all'
require 'active_document/matcher/and'
require 'active_document/matcher/bits'
require 'active_document/matcher/bits_all_clear'
require 'active_document/matcher/bits_all_set'
require 'active_document/matcher/bits_any_clear'
require 'active_document/matcher/bits_any_set'
require 'active_document/matcher/elem_match'
require 'active_document/matcher/elem_match_expression'
require 'active_document/matcher/eq'
require 'active_document/matcher/eq_impl'
require 'active_document/matcher/eq_impl_with_regexp'
require 'active_document/matcher/exists'
require 'active_document/matcher/expression'
require 'active_document/matcher/field_expression'
require 'active_document/matcher/gt'
require 'active_document/matcher/gte'
require 'active_document/matcher/in'
require 'active_document/matcher/lt'
require 'active_document/matcher/lte'
require 'active_document/matcher/mod'
require 'active_document/matcher/ne'
require 'active_document/matcher/nin'
require 'active_document/matcher/nor'
require 'active_document/matcher/not'
require 'active_document/matcher/or'
require 'active_document/matcher/regex'
require 'active_document/matcher/size'
require 'active_document/matcher/type'
require 'active_document/matcher/expression_operator'
require 'active_document/matcher/field_operator'
