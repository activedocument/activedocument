# frozen_string_literal: true

class Jar
  include ActiveDocument::Document
  include ActiveDocument::Timestamps::Updated

  field :_id, type: :integer, overwrite: true
  has_many :cookies, class_name: 'Cookie'
end
