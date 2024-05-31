# frozen_string_literal: true

module ActiveDocument
  module Extensions

    # Adds type-casting behavior to Set class.
    module Set
      # Turn the object from the ruby type we deal with to a Mongo friendly
      # type.
      #
      # @example Mongoize the object.
      #   set.mongoize
      #
      # @return [ Array | nil ] The object mongoized or nil.
      def mongoize
        ::Set.mongoize(self)
      end

      module ClassMethods
        # Convert the object from its mongo friendly ruby type to this type.
        #
        # @example Demongoize the object.
        #   Set.demongoize([1, 2, 3])
        #
        # @param [ Array ] object The object to demongoize.
        #
        # @return [ Set ] The set.
        def to_ruby_casted(object)
          case object
          when ::Set then object
          when ::Array then ::Set.new(object)
          end
        end

        # Turn the object from the ruby type we deal with to a Mongo friendly
        # type.
        #
        # @example Mongoize the object.
        #   Set.mongoize(Set.new([1,2,3]))
        #
        # @param [ Set ] object The object to mongoize.
        #
        # @return [ Array | nil ] The object mongoized or nil.
        def to_database_casted(object)
          return if object.nil?

          case object
          when ::Set then ::Array.mongoize(object.to_a).uniq
          when ::Array then ::Array.mongoize(object).uniq
          end
        end
      end
    end
  end
end

Set.include ActiveDocument::Extensions::Set
Set.extend(ActiveDocument::Extensions::Set::ClassMethods)
