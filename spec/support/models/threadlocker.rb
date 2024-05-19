# frozen_string_literal: true

class Threadlocker
  include ActiveDocument::Document

  belongs_to :hole
end
