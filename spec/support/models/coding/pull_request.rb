# frozen_string_literal: true

module Coding
  class PullRequest
    include ActiveDocument::Document

    field :title, type: String

    has_many :reviews, class_name: 'Publication::Review', as: :reviewable
  end
end
