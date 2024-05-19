# frozen_string_literal: true

require 'active_document/deprecation'

module ActiveDocument

  # Adds ability to declare ActiveDocument-specific deprecations.
  #
  # @api private
  module Deprecable

    # Declares method(s) as deprecated.
    #
    # @example Deprecate a method.
    #   ActiveDocument.deprecate(Cat, :meow); Cat.new.meow
    #   #=> ActiveDocument.logger.warn("meow is deprecated and will be removed from ActiveDocument 8.0")
    #
    # @example Deprecate a method and declare the replacement method.
    #   ActiveDocument.deprecate(Cat, meow: :speak); Cat.new.meow
    #   #=> ActiveDocument.logger.warn("meow is deprecated and will be removed from ActiveDocument 8.0 (use speak instead)")
    #
    # @example Deprecate a method and give replacement instructions.
    #   ActiveDocument.deprecate(Cat, meow: 'eat :catnip instead'); Cat.new.meow
    #   #=> ActiveDocument.logger.warn("meow is deprecated and will be removed from ActiveDocument 8.0 (eat :catnip instead)")
    #
    # @param [ Module ] target_module The parent which contains the method.
    # @param [ [ Symbol | Hash<Symbol, [ Symbol | String ]> ]... ] *method_descriptors
    #   The methods to deprecate, with optional replacement instructions.
    def deprecate(target_module, *method_descriptors)
      @_deprecator ||= ActiveDocument::Deprecation.new
      @_deprecator.deprecate_methods(target_module, *method_descriptors)
    end
  end
end

# Ensure ActiveDocument.deprecate can be used during initialization
ActiveDocument.extend(ActiveDocument::Deprecable)
