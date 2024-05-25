# frozen_string_literal: true

# This class is used for embedded matcher testing.
class Mop
  include ActiveDocument::Document

  # The dynamic attributes are used so that the tests can use various
  # field names as makes sense for the particular operator.
  include ActiveDocument::Attributes::Dynamic

  # We need some fields of specific types because the query conditions are
  # transformed differently based on the type of field being queried.
  field :int_field, type: :integer
  field :array_field, type: :array
  field :date_field, type: :date
  field :time_field, type: :time
  field :datetime_field, type: :date_time
  field :big_decimal_field, type: :big_decimal
  field :decimal128_field, type: :big_decimal
  field :symbol_field, type: :symbol
  field :regexp_field, type: :regexp
end
