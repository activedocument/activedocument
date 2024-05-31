# frozen_string_literal: true

module ActiveDocument
  module Extensions
    # Adds type-casting behavior to Object class.
    module Object
      def self.included(base)
        base.extend(ClassMethods)
      end

      # Evolve a plain object into an object id.
      #
      # @example Evolve the object.
      #   object.to_query_object_id
      #
      # @return [ Object ] self.
      def to_query_object_id
        self
      end
      alias_method :to_database_object_id, :to_query_object_id

      # Turn the object from the ruby type we deal with to a Mongo friendly
      # type.
      #
      # @example Mongoize the object.
      #   object.mongoize
      #
      # @return [ Object ] The object.
      def mongoize
        self
      end

      module ClassMethods

        # Convert the object from its mongo friendly ruby type to this type.
        #
        # @example Demongoize the object.
        #   Object.demongoize(object)
        #
        # @param [ Object ] object The object to demongoize.
        #
        # @return [ Object ] The object.
        def to_ruby_casted(object)
          object
        end

        # Turn the object from the ruby type we deal with to a Mongo friendly
        # type.
        #
        # @example Mongoize the object.
        #   Object.mongoize("123.11")
        #
        # @param [ Object ] object The object to mongoize.
        #
        # @return [ Object ] The object mongoized.
        def to_database_casted(object)
          object.mongoize
        end
      end
    end
  end
end

Object.include(ActiveDocument::Extensions::Object)
