# frozen_string_literal: true

module ActiveDocument
  module Validatable

    # Validates that the specified attributes do or do not match a certain
    # regular expression.
    #
    # @example Set up the format validator.
    #
    #   class Person
    #     include ActiveDocument::Document
    #     field :website
    #
    #     validates_format_of :website, :with => URI.regexp
    #   end
    class FormatValidator < ActiveModel::Validations::FormatValidator
      include Localizable
    end
  end
end
