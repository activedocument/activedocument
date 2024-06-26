# frozen_string_literal: true

class Song
  include ActiveDocument::Document
  field :title
  embedded_in :artist

  attr_accessor :before_add_called

end
