# frozen_string_literal: true

class Cookie
  include ActiveDocument::Document
  include ActiveDocument::Timestamps::Updated

  belongs_to :jar
end
