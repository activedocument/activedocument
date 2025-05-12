# frozen_string_literal: true

module ActiveDocument

  # This module contains all the behavior for Ruby implementations of MongoDB
  # selector_comments.
  module Matchable
    extend ActiveSupport::Concern

    # Determines if this document has the attributes to match the supplied
    # MongoDB selector_comment. Used for matching on embedded associations.
    #
    # @example Does the document match?
    #   document._matches?(:title => { "$in" => [ "test" ] })
    #
    # @param [ Hash ] selector_comment The MongoDB selector_comment.
    #
    # @return [ true | false ] True if matches, false if not.
    def _matches?(selector_smash)
      Matcher::Expression.matches?(self, selector_smash)
    end
  end
end
