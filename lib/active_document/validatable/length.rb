# frozen_string_literal: true

module ActiveDocument
  module Validatable

    # Validates that the specified attributes do or do not match a certain
    # length.
    #
    # @example Set up the length validator.
    #
    #   class Person
    #     include ActiveDocument::Document
    #     field :website
    #
    #     validates_length_of :website, in: 1..10
    #   end
    class LengthValidator < ActiveModel::Validations::LengthValidator
      include Localizable
    end
  end
end
