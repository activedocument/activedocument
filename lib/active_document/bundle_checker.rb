# frozen_string_literal: true

require 'active_document/errors'

module ActiveDocument

  # Checks for gem conflicts in the bundle.
  #
  # @api private
  module BundleChecker
    extend self

    # Checks whether the a gem is present in the bundle,
    # and raises an error if it is.
    #
    # @raise [ ActiveDocument::Errors::GemConflict ] If the gem is present.
    #
    # @api private
    def check_gem_absent!(gem_name)
      return true if !defined?(Bundler) || !find_gem(gem_name)

      raise Errors::GemConflict.new(gem_name)
    end

    private

    def find_gem(gem_name)
      !!Gem::Specification.find_by_name(gem_name)
    rescue Gem::MissingSpecError
      false
    end
  end
end

ActiveDocument::BundleChecker.check_gem_absent!('active_document')
