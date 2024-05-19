# frozen_string_literal: true

class Kangaroo
  include ActiveDocument::Document
  embeds_one :baby
end
