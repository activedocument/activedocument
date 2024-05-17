# frozen_string_literal: true

class Baby
  include ActiveDocument::Document
  embedded_in :kangaroo
end
