# frozen_string_literal: true

module ActiveDocument
  module Errors

    # This error should be raised to deliberately rollback a transaction without
    # passing on an exception.
    # Normally, raising an exception inside a ActiveDocument transaction causes rolling
    # the MongoDB transaction back, and the exception is passed on.
    # If ActiveDocument::Error::Rollback exception is raised, then the MongoDB
    # transaction will be rolled back, without passing on the exception.
    class Rollback < BaseError; end
  end
end
