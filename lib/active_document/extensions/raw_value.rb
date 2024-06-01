# frozen_string_literal: true

# Wrapper class used when a value cannot be casted in evolve method.
module ActiveDocument

  # Instantiates a new ActiveDocument::RawValue object. Used as a syntax shortcut.
  #
  # @example Create a ActiveDocument::RawValue object.
  #   ActiveDocument::RawValue("Beagle")
  #
  # @return [ ActiveDocument::RawValue ] The object.
  def RawValue(*args) # rubocop:disable Naming/MethodName
    RawValue.new(*args)
  end

  # Represents a value which cannot be type-casted between Ruby and MongoDB.
  class RawValue

    attr_reader :raw_value

    def initialize(raw_value)
      @raw_value = raw_value
    end

    # Returns a string containing a human-readable representation of
    # the object, including the inspection of the underlying value.
    #
    # @return [ String ] The object inspection.
    def inspect
      "RawValue: #{raw_value.inspect}"
    end

    # Returns whether the other object is equal to this one.
    #
    # @param [ Object ] other The object to compare.
    #
    # @return [ true, false ] The result.
    def ==(other)
      other.is_a?(RawValue) && raw_value == other.raw_value
    end
  end
end
