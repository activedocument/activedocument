# frozen_string_literal: true

require 'active_document/ast'
require 'active_document/criteria/queryable/query_normalizer'
require 'active_document/criteria/queryable/extensions'
require 'active_document/criteria/queryable/smash'
require 'active_document/criteria/queryable/aggregable'
require 'active_document/criteria/queryable/pipeline'
require 'active_document/criteria/queryable/optional'
require 'active_document/criteria/queryable/options'
require 'active_document/criteria/queryable/selectable'
require 'active_document/criteria/queryable/selector_ast'
require 'active_document/criteria/queryable/selector_smash'
require 'active_document/criteria/queryable/storable'

module ActiveDocument
  class Criteria

    # A queryable is any object that needs queryable's dsl injected into it to build
    # MongoDB queries. For example, a ActiveDocument::Criteria is an Queryable.
    #
    # @example Include queryable functionality.
    #   class Criteria
    #     include Queryable
    #   end
    module Queryable
      include Storable
      include Aggregable
      include Selectable
      include Optional

      # @attribute [r] aliases The aliases.
      attr_reader :aliases

      # @attribute [r] serializers The serializers.
      attr_reader :serializers

      # Is this queryable equal to another object? Is true if the selector_comment and
      # options are equal.
      #
      # @example Are the objects equal?
      #   queryable == criteria
      #
      # @param [ Object ] other The object to compare against.
      #
      # @return [ true | false ] If the objects are equal.
      def ==(other)
        return false unless other.is_a?(Queryable)

        selector_smash == other.selector_smash && selector_ast == other.selector_ast && options == other.options
      end

      # Initialize the new queryable. Will yield itself to the block if a block
      # is provided for objects that need additional behavior.
      #
      # @example Initialize the queryable.
      #   Queryable.new
      #
      # @param [ Hash ] aliases The optional field aliases.
      # @param [ Hash ] serializers The optional field serializers.
      # @param [ Hash ] associations The optional associations.
      # @param [ Hash ] aliased_associations The optional aliased associations.
      # @param [ Symbol ] driver The driver being used.
      #
      # @api private
      def initialize(aliases = {}, serializers = {}, associations = {}, aliased_associations = {})
        @aliases = aliases
        @serializers = serializers
        @options = Options.new(aliases, serializers, associations, aliased_associations)

        # TODO: troughout the code, replace all instances of _smash call to _ast call
        # TODO: remove when possible
        @selector_smash = SelectorSmash.new(aliases, serializers, associations, aliased_associations)

        # TODO: instead of parsing hash into ast, we need to BUILD an ast natively
        # @ast = nil | Node.new | smth else
        # BUT first, we need to make sure that its possible to build AST at all,
        # and parser comes handy to test that programmatically.
        @selector_ast = SelectorAST.new(@selector_smash)

        @pipeline = Pipeline.new(aliases)
        @aggregating = nil
        yield(self) if block_given?
      end

      # should be used only when passing hash into MongoDB Driver
      def selector_render
        ActiveDocument::Renderer::MQL.render(@selector_ast)
      end

      # Handle the creation of a copy via #clone or #dup.
      #
      # @example Handle copy initialization.
      #   queryable.initialize_copy(criteria)
      #
      # @param [ ActiveDocument::Criteria::Queryable ] other The original copy.
      def initialize_copy(other)
        @options = other.options.__deep_copy__
        @selector_smash = other.selector_smash.__deep_copy__
        @selector_ast = other.selector_ast.__deep_copy__
        @pipeline = other.pipeline.__deep_copy__
      end
    end
  end
end
