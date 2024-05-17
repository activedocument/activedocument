# frozen_string_literal: true

class Appointment
  include ActiveDocument::Document
  field :active, type: ActiveDocument::Boolean, default: true
  field :timed, type: ActiveDocument::Boolean, default: true
  embedded_in :person
  default_scope -> { where(active: true) }
end
