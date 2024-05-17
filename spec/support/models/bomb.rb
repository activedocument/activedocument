# frozen_string_literal: true

class Bomb
  include ActiveDocument::Document
  has_one :explosion, dependent: :delete_all, autobuild: true
end
