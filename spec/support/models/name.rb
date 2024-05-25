# frozen_string_literal: true

class Name
  include ActiveDocument::Document
  include ActiveDocument::Attributes::Dynamic

  validate :is_not_jamis

  field :_id, type: :string, overwrite: true, default: lambda {
    "#{first_name}-#{last_name}"
  }

  field :first_name, type: :string
  field :last_name, type: :string
  field :parent_title, type: :string
  field :middle, type: :string

  embeds_many :translations, validate: false
  embeds_one :language, as: :translatable, validate: false
  embedded_in :namable, polymorphic: true
  embedded_in :person

  accepts_nested_attributes_for :language

  def set_parent=(set = false)
    self.parent_title = namable.title if set
  end

  private

  def is_not_jamis
    return unless first_name == 'Jamis' && last_name == 'Buck'

    errors.add(:base, :invalid)
  end
end
