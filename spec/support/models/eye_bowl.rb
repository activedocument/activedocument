# frozen_string_literal: true

class EyeBowl
  include ActiveDocument::Document

  has_many :blue_eyes, class_name: 'Eye', as: :eyeable
  has_many :brown_eyes, class_name: 'Eye', as: :eyeable

  has_one :face, as: :suspended_in
  has_one :eye, as: :suspended_in
end
