# frozen_string_literal: true

require 'active_document/atomic/paths/embedded/one'
require 'active_document/atomic/paths/embedded/many'

module ActiveDocument
  module Atomic
    module Paths

      # Common functionality between the two different embedded paths.
      module Embedded

        attr_reader :delete_modifier, :document, :insert_modifier, :parent

        # Get the path to the document in the hierarchy.
        #
        # @example Get the path.
        #   many.path
        #
        # @return [ String ] The path to the document.
        def path
          @path ||= position.sub(/\.\d+\z/, '')
        end
      end
    end
  end
end
