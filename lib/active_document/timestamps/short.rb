# frozen_string_literal: true

module ActiveDocument
  module Timestamps
    module Short
      extend ActiveSupport::Concern
      include Created::Short
      include Updated::Short
    end
  end
end
