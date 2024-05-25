# frozen_string_literal: true

class Animal
  include ActiveDocument::Document

  field :_id, type: :string, overwrite: true, default: -> { name.try(:parameterize) }

  field :name
  field :height, type: :integer
  field :weight, type: :integer
  field :tags, type: :array

  embedded_in :person

  # class_name is necessary because ActiveRecord thinks the singular of "Circus" is "Circu"
  embedded_in :circus, class_name: 'Circus'

  validates_format_of :name, without: /\$\$\$/

  accepts_nested_attributes_for :person

  def tag_list
    tags.join(', ')
  end

  def tag_list=(tg_list)
    self.tags = tg_list.split(',').map(&:strip)
  end
end
