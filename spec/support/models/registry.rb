# frozen_string_literal: true

class Registry
  include ActiveDocument::Document
  field :data, type: :binary
  field :obj_id, type: :bson_object_id
end
