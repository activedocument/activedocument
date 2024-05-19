# frozen_string_literal: true

module ActiveDocument
  module Association
    module Embedded
      class EmbeddedIn

        # The Builder behavior for embedded_in associations.
        module Buildable
          include Threaded::Lifecycle

          # This builder doesn't actually build anything, just returns the
          # parent since it should already be instantiated.
          #
          # @example Build the document.
          #   Builder.new(meta, attrs).build
          #
          # @param [ ActiveDocument::Document ] _base The object.
          # @param [ ActiveDocument::Document | Hash ] object The parent hash or document.
          # @param [ String ] _type Not used in this context.
          # @param [ Hash ] selected_fields Fields which were retrieved via
          #   #only. If selected_fields are specified, fields not listed in it
          #   will not be accessible in the built document.
          #
          # @return [ ActiveDocument::Document ] A single document.
          def build(_base, object, _type = nil, selected_fields = nil)
            return object unless object.is_a?(Hash)

            if _loading?
              Factory.from_db(klass, object, nil, selected_fields)
            else
              Factory.build(klass, object)
            end
          end
        end
      end
    end
  end
end
