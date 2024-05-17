# frozen_string_literal: true

module ActiveDocument

  # Utility class for logging deprecation warnings.
  class Deprecation < ::ActiveSupport::Deprecation

    def initialize
      # Per change policy, deprecations will be removed in the next major version.
      deprecation_horizon = "#{ActiveDocument::VERSION.split('.').first.to_i + 1}.0"
      gem_name = 'ActiveDocument'
      super(deprecation_horizon, gem_name)
    end

    # Overrides default ActiveSupport::Deprecation behavior
    # to use ActiveDocument's logger.
    #
    # @return [ Array<Proc> ] The deprecation behavior.
    def behavior
      @behavior ||= Array(lambda do |*args|
        logger = ActiveDocument.logger
        logger.warn(args[0])
        logger.debug(args[1].join("\n  ")) if debug
      end)
    end
  end
end
