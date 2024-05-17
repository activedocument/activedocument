# frozen_string_literal: true

require 'active_document/association/nested/nested_buildable'
require 'active_document/association/nested/many'
require 'active_document/association/nested/one'

module ActiveDocument
  module Association
    module Nested

      # The flags indicating that an association can be destroyed.
      DESTROY_FLAGS = [1, '1', true, 'true'].freeze
    end
  end
end
