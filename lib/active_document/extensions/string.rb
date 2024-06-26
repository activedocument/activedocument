# frozen_string_literal: true

module ActiveDocument
  module Extensions

    # Adds type-casting behavior to String class.
    module String

      # Convert the string to a collection friendly name.
      #
      # @example Collectionize the string.
      #   "namespace/model".collectionize
      #
      # @return [ String ] The string in collection friendly form.
      def collectionize
        tableize.tr('/', '_')
      end

      # Is the string a number? The literals "NaN", "Infinity", and "-Infinity"
      # are counted as numbers.
      #
      # @example Is the string a number.
      #   "1234.23".numeric?
      #
      # @return [ true | false ] If the string is a number.
      def numeric?
        !!Float(self)
      rescue ArgumentError
        (self =~ /\A(?:NaN|-?Infinity)\z/) == 0
      end

      # Get the string as a getter string.
      #
      # @example Get the reader/getter
      #   "model=".reader
      #
      # @return [ String ] The string stripped of "=".
      def reader
        delete('=').delete_suffix('_before_type_cast')
      end

      # Is this string a writer?
      #
      # @example Is the string a setter method?
      #   "model=".writer?
      #
      # @return [ true | false ] If the string contains "=".
      def writer?
        include?('=')
      end

      # Is this string a valid_method_name?
      #
      # @example Is the string a valid Ruby identifier for use as a method name
      #   "model=".valid_method_name?
      #
      # @return [ true | false ] If the string contains a valid Ruby identifier.
      def valid_method_name?
        /[@$"-]/ !~ self
      end

      # Does the string end with _before_type_cast?
      #
      # @example Is the string a setter method?
      #   "price_before_type_cast".before_type_cast?
      #
      # @return [ true | false ] If the string ends with "_before_type_cast"
      def before_type_cast?
        ends_with?('_before_type_cast')
      end

      module ClassMethods

        # Turn the object from the ruby type we deal with to a Mongo friendly
        # type.
        #
        # @example Mongoize the object.
        #   String.mongoize("123.11")
        #
        # @param [ Object ] object The object to mongoize.
        #
        # @return [ String ] The object mongoized.
        def mongoize(object)
          object.try(:to_s)
        end
        alias_method :demongoize, :mongoize
      end
    end
  end
end

String.include ActiveDocument::Extensions::String
String.extend(ActiveDocument::Extensions::String::ClassMethods)
