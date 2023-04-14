# frozen_string_literal: true

class Animal
  include Mongoid::Document

  field :_id, type: String, overwrite: true, default: -> { name.try(:parameterize) }

  field :name
  field :height, type: Integer
  field :weight, type: Integer
  field :tags, type: Array

  embedded_in :person

  # class_name is necessary because ActiveRecord thinks the singular of "Circus" is "Circu"
  embedded_in :circus, class_name: 'Circus'

  validates_format_of :name, without: /\$\$\$/

  accepts_nested_attributes_for :person

  def tag_list
    tags.join(", ")
  end

  def tag_list=(_tag_list)
    self.tags = _tag_list.split(",").map(&:strip)
  end
end
