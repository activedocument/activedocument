# frozen_string_literal: true

class AccountAutosave
  include ActiveDocument::Document

  field :_id, type: :string, overwrite: true, default: -> { name.try(:parameterize) }

  field :number, type: :string
  field :balance, type: :integer
  field :nickname, type: :string
  field :name, type: :string
  field :balanced, type: :boolean, default: -> { balance? }

  field :overridden, type: :string

  embeds_many :memberships
  belongs_to :creator, class_name: 'User'
  belongs_to :person, class_name: 'PersonAutosave'
  has_many :alerts, autosave: false
  has_and_belongs_to_many :agents
  has_one :comment, validate: false

  validates_presence_of :name
  validates_presence_of :nickname, on: :upsert
  validates_length_of :name, maximum: 10, on: :create

  def overridden
    self[:overridden] = 'not recommended'
  end

  # MONGOID-3365
  field :period_started_at, type: :time
  has_many :consumption_periods, dependent: :destroy, validate: false

  def current_consumption
    consumption_periods.find_or_create_by(started_at: period_started_at)
  end
end
