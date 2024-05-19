# frozen_string_literal: true

class Face
  include ActiveDocument::Document

  has_one :left_eye, class_name: 'Eye', as: :eyeable
  has_one :right_eye, class_name: 'Eye', as: :eyeable

  belongs_to :suspended_in, polymorphic: true
end
