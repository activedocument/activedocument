# frozen_string_literal: true

require 'active_document/timestamps/timeless'
require 'active_document/timestamps/created'
require 'active_document/timestamps/updated'
require 'active_document/timestamps/short'

module ActiveDocument

  # This module handles the behavior for setting up document created at and
  # updated at timestamps.
  module Timestamps
    extend ActiveSupport::Concern
    include Created
    include Updated
  end
end
