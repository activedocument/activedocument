# frozen_string_literal: true

class Band
  include ActiveDocument::Document
  include ActiveDocument::Attributes::Dynamic

  field :name, type: String
  field :active, type: ActiveDocument::Boolean, default: true
  field :origin, type: String
  field :genres, type: Array
  field :member_count, type: Integer
  field :mems, as: :members, type: Array
  field :likes, type: Integer
  field :views, type: Integer
  field :rating, type: Float
  field :upserted, type: ActiveDocument::Boolean, default: false
  field :created, type: DateTime
  field :updated, type: Time
  field :sales, type: BigDecimal
  field :decimal, type: BSON::Decimal128
  field :y, as: :years, type: Integer
  field :founded, type: Date
  field :decibels, type: Range
  field :deleted, type: Boolean
  field :mojo, type: Object
  field :tags, type: Hash
  field :fans

  alias_attribute :d, :deleted

  embeds_many :records, cascade_callbacks: true
  embeds_many :notes, as: :noteable, cascade_callbacks: true, validate: false
  embeds_many :labels
  embeds_many :fanatics
  embeds_one :label, cascade_callbacks: true

  scope :highly_rated, -> { gte(rating: 7) }

  has_many :artists
  has_many :same_name, class_name: 'Agent', inverse_of: :same_name

  after_upsert do |doc|
    doc.upserted = true
  end
end
