# frozen_string_literal: true

class CountryCode
  include ActiveDocument::Document

  field :_id, type: :integer, overwrite: true, default: -> { code }

  field :code, type: :integer
  field :iso, as: :iso_alpha2_code

  embedded_in :phone_number, class_name: 'Phone'
end
