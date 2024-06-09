# frozen_string_literal: true

module ActiveDocument
  module Extensions
    # Adds type-casting behavior to Array class.
    module Array

      # Turn the object from the ruby type we deal with to a Mongo friendly
      # type.
      #
      # @example Mongoize the object.
      #   object.mongoize
      #
      # @return [ Array | nil ] The object or nil.
      def mongoize
        ::Array.mongoize(self)
      end

      # Delete the first object in the array that is equal to the supplied
      # object and return it. This is much faster than performing a standard
      # delete for large arrays since it does not perform multiple deletes.
      #
      # @example Delete the first object.
      #   [ "1", "2", "1" ].delete_one("1")
      #
      # @param [ Object ] object The object to delete.
      #
      # @return [ Object ] The deleted object.
      def delete_one(object)
        position = index(object)
        position ? delete_at(position) : nil
      end

      # Returns whether the object's size can be changed.
      #
      # @example Is the object resizable?
      #   object.resizable?
      #
      # @return [ true ] true.
      def resizable?
        true
      end

      module ClassMethods

        # Turn the object from the ruby type we deal with to a Mongo friendly
        # type.
        #
        # @example Mongoize the object.
        #   Array.mongoize([ 1, 2, 3 ])
        #
        # @param [ Object ] object The object to mongoize.
        #
        # @return [ Array | nil ] The object mongoized or nil.
        def mongoize(object)
          return if object.nil?

          case object
          when ::Array, ::Set
            object.map(&:mongoize)
          end
        end

        # Returns whether the object's size can be changed.
        #
        # @example Is the object resizable?
        #   Array.resizable?
        #
        # @return [ true ] true.
        def resizable?
          true
        end
      end
    end
  end
end

Array.include(ActiveDocument::Extensions::Array)
Array.extend(ActiveDocument::Extensions::Array::ClassMethods)
