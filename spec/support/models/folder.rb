# frozen_string_literal: true

class Folder
  include ActiveDocument::Document

  field :name, type: :string
  has_many :folder_items

end
