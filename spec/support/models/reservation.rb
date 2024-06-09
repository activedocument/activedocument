# frozen_string_literal: true

class Reservation
  include ActiveDocument::Document
  field :deleted_at, type: Time
  default_scope -> { where(deleted_at: nil) }
end
