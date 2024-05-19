# frozen_string_literal: true

module ActiveDocument
  module Config
    module Validators

      # Validates the async query executor options in the ActiveDocument
      # configuration. Used during application bootstrapping.
      #
      # @api private
      module AsyncQueryExecutor
        extend self

        # Validate the ActiveDocument configuration options related to
        # the async query executor.
        #
        # @param [ Hash ] options The configuration options.
        #
        # @raises [ ActiveDocument::Errors::InvalidGlobalExecutorConcurrency ]
        #   Raised if the options are invalid.
        #
        # @api private
        def validate(options)
          return unless options.key?(:async_query_executor) &&
                        (options[:async_query_executor].to_sym == :immediate &&
                        !options[:global_executor_concurrency].nil?)

          raise Errors::InvalidGlobalExecutorConcurrency
        end
      end
    end
  end
end
