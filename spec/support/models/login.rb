# frozen_string_literal: true

class Login
  include ActiveDocument::Document

  field :_id, type: String, overwrite: true, default: -> { username }

  field :username, type: String
  field :application_id, type: Integer
end
