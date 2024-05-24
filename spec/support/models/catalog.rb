# frozen_string_literal: true

class Catalog
  include ActiveDocument::Document

  field :array_field, type: :array
  field :big_decimal_field, type: :big_decimal
  field :boolean_field, type: :boolean
  field :date_field, type: :date
  field :date_time_field, type: :date_time
  field :float_field, type: :float
  field :hash_field, type: :hash
  field :integer_field, type: :integer
  field :object_id_field, type: :bson_object_id
  field :binary_field, type: :binary
  field :range_field, type: :range
  field :regexp_field, type: :regexp
  field :set_field, type: :set
  field :string_field, type: :string
  field :stringified_symbol_field, type: :stringified_symbol
  field :symbol_field, type: :symbol
  field :time_field, type: :time
  field :time_with_zone_field, type: :time
end
