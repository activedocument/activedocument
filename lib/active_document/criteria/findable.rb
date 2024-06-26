# frozen_string_literal: true

module ActiveDocument
  class Criteria

    # Mixin module included in ActiveDocument::Criteria which adds the ability
    # to find document by id.
    module Findable

      # Execute the criteria or raise an error if no documents found.
      #
      # @example Execute or raise
      #   criteria.execute_or_raise(id)
      #
      # @param [ Object ] ids The arguments passed.
      # @param [ true | false ] multi Whether there arguments were a list,
      #   and therefore the return value should be an array.
      #
      # @raise [ Errors::DocumentNotFound ] If nothing returned.
      #
      # @return [ ActiveDocument::Document | Array<ActiveDocument::Document> ] The document(s).
      def execute_or_raise(ids, multi)
        result = multiple_from_db(ids)
        check_for_missing_documents!(result, ids)
        multi ? result : result.first
      end

      # Find the matching document(s) in the criteria for the provided id(s).
      #
      # @note Each argument can be an individual id, an array of ids or
      #   a nested array. Each array will be flattened.
      #
      # @example Find by an id.
      #   criteria.find(BSON::ObjectId.new)
      #
      # @example Find by multiple ids.
      #   criteria.find([ BSON::ObjectId.new, BSON::ObjectId.new ])
      #
      # @param [ [ Object | Array<Object> ]... ] *args The id(s) to find.
      #
      # @return [ ActiveDocument::Document | Array<ActiveDocument::Document> ] The matching document(s).
      def find(*args)
        ids = prepare_ids_for_find(args)
        raise_invalid if ids.any?(&:nil?)
        for_ids(ids).execute_or_raise(ids, multi_args?(args))
      end

      # Adds a criterion to the +Criteria+ that specifies an id that must be matched.
      #
      # @example Add a single id criteria.
      #   criteria.for_ids([ 1 ])
      #
      # @example Add multiple id criteria.
      #   criteria.for_ids([ 1, 2 ])
      #
      # @param [ Array ] ids The array of ids.
      #
      # @return [ ActiveDocument::Criteria ] The cloned criteria.
      def for_ids(ids)
        ids = mongoize_ids(ids)
        if ids.size > 1
          send(id_finder, { _id: { '$in' => ids } })
        else
          send(id_finder, { _id: ids.first })
        end
      end

      # Get the documents from the identity map, and if not found hit the
      # database.
      #
      # @example Get the documents from the map or criteria.
      #   criteria.multiple_from_map_or_db(ids)
      #
      # @param [ Array<Object> ] ids The searched ids.
      #
      # @return [ Array<ActiveDocument::Document> ] The found documents.
      def multiple_from_db(ids)
        return entries if embedded?

        ids = mongoize_ids(ids)
        ids.empty? ? [] : from_database(ids)
      end

      private

      # Get the finder used to generate the id query.
      #
      # @api private
      #
      # @example Get the id finder.
      #   criteria.id_finder
      #
      # @return [ Symbol ] The name of the finder method.
      def id_finder
        @id_finder ||= extract_id ? :all_of : :where
      end

      # Get documents from the database only.
      #
      # @api private
      #
      # @example Get documents from the database.
      #   criteria.from_database(ids)
      #
      # @param [ Array<Object> ] ids The ids to fetch with.
      #
      # @return [ Array<ActiveDocument::Document> ] The matching documents.
      def from_database(ids)
        from_database_selector(ids).entries
      end

      # Returns a query criteria to select the document(s) for the given id(s).
      #
      # @api private
      #
      # @param [ Array<BSON::ObjectId> ] ids The ids to fetch with.
      #
      # @return [ ActiveDocument::Criteria ] The criteria.
      def from_database_selector(ids)
        if ids.size > 1
          any_in(_id: ids)
        else
          where(_id: ids.first)
        end
      end

      # Convert all the ids to their proper types.
      #
      # @api private
      #
      # @example Convert the ids.
      #   criteria.mongoize_ids(ids)
      #
      # @param [ Array<Object> ] ids The ids to convert.
      #
      # @return [ Array<Object> ] The converted ids.
      def mongoize_ids(ids)
        ids.map do |id|
          id = id[:_id] if id.respond_to?(:keys) && id[:_id]
          klass.fields['_id'].mongoize(id)
        end
      end

      # Convert args to the +#find+ method into a flat array of ids.
      #
      # @example Get the ids.
      #   prepare_ids_for_find([ 1, [ 2, 3 ] ])
      #
      # @param [ Array<Object> ] args The arguments.
      #
      # @return [ Array ] The array of ids.
      def prepare_ids_for_find(args)
        args.flat_map do |arg|
          case arg
          when Array, Set
            prepare_ids_for_find(arg)
          when Range
            arg.begin&.numeric? && arg.end&.numeric? ? arg.to_a : arg
          else
            arg
          end
        end.uniq(&:to_s)
      end

      # Indicates whether the given arguments array is a list of values.
      # Used by the +find+ method to determine whether to return an array
      # or single value.
      #
      # @example Are these arguments a list of values?
      #   multi_args?([ 1, 2, 3 ]) #=> true
      #
      # @param [ Array ] args The arguments.
      #
      # @return [ true | false ] Whether the arguments are a list.
      def multi_args?(args)
        args.size > 1 || (!args.first.is_a?(Hash) && args.first.resizable?)
      end

      # Convenience method of raising an invalid options error.
      #
      # @example Raise the error.
      #   criteria.raise_invalid
      #
      # @raise [ Errors::InvalidOptions ] The error.
      def raise_invalid
        raise Errors::InvalidFind
      end
    end
  end
end
