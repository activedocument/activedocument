# frozen_string_literal: true

class Updatable
  include ActiveDocument::Document

  field :updated_at, type: BSON::Timestamp
end
