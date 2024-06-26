# frozen_string_literal: true

class Player
  include ActiveDocument::Document
  field :active, type: :boolean
  field :frags, type: :integer
  field :deaths, type: :integer
  field :impressions, type: :integer, default: 0
  field :status

  scope :active, -> { where(active: true) } do
    def extension
      'extension'
    end
  end

  scope :inactive, -> { where(active: false) }
  scope :frags_over, ->(count) { where(frags: { '$gt' => count }) }
  scope :deaths_under, ->(count) { where(deaths: { '$lt' => count }) }
  scope :deaths_over, ->(count) { where(deaths: { '$gt' => count }) }

  has_many :weapons
  has_one :powerup

  embeds_many :implants
  embeds_one :augmentation

  has_and_belongs_to_many :shields

  after_find do |doc|
    doc.impressions += 1
  end

  class << self
    def alive
      where(status: 'Alive')
    end
  end
end
