# frozen_string_literal: true

module Dynamoid
  # @private
  module AdapterPlugin
    class AwsSdkV3
      module Middleware
        class Backoff
          def initialize(next_chain)
            @next_chain = next_chain
            @backoff = Dynamoid.config.backoff ? Dynamoid.config.build_backoff : nil
          end

          def call(request)
            response = @next_chain.call(request)
            @backoff.call if @backoff

            response
          end
        end
      end
    end
  end
end
