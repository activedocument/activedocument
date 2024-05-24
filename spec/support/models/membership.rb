# frozen_string_literal: true

class Membership
  include ActiveDocument::Document
  field :name, type: :string
  embedded_in :account
end
