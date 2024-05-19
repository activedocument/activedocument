# frozen_string_literal: true

class FolderItem

  include ActiveDocument::Document

  belongs_to :folder
  field :name, type: String

  validates :name, uniqueness: { scope: :folder_id }
end
