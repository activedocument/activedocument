# frozen_string_literal: true

class PageQuestion
  include ActiveDocument::Document
  embedded_in :page
end
