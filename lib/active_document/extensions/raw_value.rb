# frozen_string_literal: true

# Wrapper class used when a value cannot be casted by the
# mongoize, demongoize, and evolve methods.
module ActiveDocument

  # Instantiates a new ActiveDocument::RawValue object. Used as a syntax shortcut.
  # Instantiates a new ActiveDocument::RawValue object. Used as a
  # syntax shortcut.
  #
  # @example Create a ActiveDocument::RawValue object.
  #   ActiveDocument::RawValue("Beagle")
  #
  # @param [ Object... ] *args The args to initialize.
  #
  # @return [ ActiveDocument::RawValue ] The object.
  def RawValue(*args) # rubocop:disable Naming/MethodName
    RawValue.new(*args)
  end

  # Represents a value which cannot be type-casted between Ruby and MongoDB.
  class RawValue

    attr_reader :raw_value,
                :cast_class_name,
                :underlying_error

    # Instantiates a new ActiveDocument::RawValue object.
    #
    # @example Create a ActiveDocument::RawValue object.
    #   ActiveDocument::RawValue.new("Beagle", "String")
    #
    # @param [ Object ] raw_value The underlying raw object.
    # @param [ String ] cast_class_name The name of the class
    #   to which the raw value is intended to be cast.
    # @param [ String ] underlying_error The error which
    #   caused the RawValue to be instantiated.
    #
    # @return [ ActiveDocument::RawValue ] The object.
    def initialize(raw_value, cast_class_name = nil, underlying_error = nil)
      @raw_value = raw_value
      @cast_class_name = cast_class_name
      @underlying_error = underlying_error
    end

    # Returns a string containing a human-readable representation of
    # the object, including the inspection of the underlying value.
    #
    # @return [ String ] The object inspection.
    def inspect
      "RawValue: #{raw_value.inspect}"
    end

    # Raises a ActiveDocument::Errors::InvalidValue error.
    def raise_error!
      raise ActiveDocument::Errors::InvalidValue.new(raw_value.class.name, cast_class_name)
    end

    # Logs a warning that a value cannot be cast.
    def warn
      Mongoid.logger.warn("Cannot cast #{raw_value.class.name} to #{cast_class_name}; returning nil")
    end

    # Logs a warning that a value cannot be cast.
    def ==(other)
      other.is_a?(RawValue) && raw_value == other.raw_value
    end

    # Delegate all missing methods to the raw value.
    #
    # @param [ String, Symbol ] method_name The name of the method.
    # @param [ Array ] args The arguments passed to the method.
    #
    # @return [ Object ] The method response.
    def method_missing(method_name, *args, &block)
      raw_value.send(method_name, *args, &block)
    end

    # Delegate all missing methods to the raw value.
    #
    # @param [ String, Symbol ] method_name The name of the method.
    # @param [ true | false ] include_private Whether to check private methods.
    #
    # @return [ true | false ] Whether the raw value object responds to the method.
    def respond_to_missing?(method_name, include_private = false)
      raw_value.respond_to?(method_name, include_private)
    end
  end
end
