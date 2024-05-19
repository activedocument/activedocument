# frozen_string_literal: true

module Publication
  class Review
    include ActiveDocument::Document

    field :summary

    belongs_to :reviewable, polymorphic: true
    belongs_to :reviewer, polymorphic: true
    belongs_to :template
  end
end
