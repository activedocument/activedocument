# frozen_string_literal: true

module ActiveDocument
  module Railties
    module ControllerRuntime

      # This extension mimics the Rails' internal method to
      # measure ActiveRecord runtime during request processing.
      # It appends MongoDB runtime value (`active_document_runtime`) into payload
      # of instrumentation event `process_action.action_controller`.
      module ControllerExtension
        extend ActiveSupport::Concern

        protected

        attr_internal :active_document_runtime

        # Reset the runtime before each action.
        def process_action(action, *args)
          Collector.reset_runtime
          super
        end

        # Override to collect the measurements.
        def cleanup_view_runtime
          mongo_rt_before_render = Collector.reset_runtime
          runtime = super
          mongo_rt_after_render = Collector.reset_runtime
          self.active_document_runtime = mongo_rt_before_render + mongo_rt_after_render
          runtime - mongo_rt_after_render
        end

        # Add the measurement to the instrumentation event payload.
        def append_info_to_payload(payload)
          super
          payload[:active_document_runtime] = (active_document_runtime || 0) + Collector.reset_runtime
        end

        module ClassMethods

          # Append MongoDB runtime information to ActionController runtime
          # log message.
          def log_process_action(payload)
            messages = super
            active_document_runtime = payload[:active_document_runtime]
            messages << format('MongoDB: %.1fms', active_document_runtime.to_f) if active_document_runtime
            messages
          end
        end
      end

      # The Collector of MongoDB runtime metric, that subscribes to Mongo
      # driver command monitoring. Stores the value within a thread-local
      # variable to provide correct accounting when an application issues
      # MongoDB operations from background threads.
      class Collector

        VARIABLE_NAME = 'ActiveDocument.controller_runtime'

        # Call when event started. Does nothing.
        #
        # @return [ nil ] Nil.
        def started(_); end

        # Call when event completed. Updates the runtime value.
        #
        # @param [ Mongo::Event::Base ] event The monitoring event.
        #
        # @return [ Integer ] The current runtime value.
        def _completed(event)
          Collector.runtime += event.duration * 1000
        end
        alias_method :succeeded, :_completed
        alias_method :failed, :_completed

        # Get the runtime value on the current thread.
        #
        # @return [ Integer ] The runtime value.
        def self.runtime
          Thread.current[VARIABLE_NAME] ||= 0
        end

        # Set the runtime value on the current thread.
        #
        # @param [ Integer ] value The runtime value.
        #
        # @return [ Integer ] The runtime value.
        def self.runtime=(value)
          Thread.current[VARIABLE_NAME] = value
        end

        # Reset the runtime value to zero the current thread.
        #
        # @return [ Integer ] The previous runtime value.
        def self.reset_runtime
          to_now = runtime
          self.runtime = 0
          to_now
        end
      end
    end
  end
end
