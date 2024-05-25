# frozen_string_literal: true

class Galaxy
  include ActiveDocument::Document
  include ActiveDocument::Timestamps

  field :age, type: :integer
  field :was_touched, type: :boolean, default: false
  before_validation :set_age

  embeds_many :stars

  set_callback(:touch, :before) do
    self.was_touched = true
  end

  private

  def set_age
    self.age ||= 100_000
  end
end

class Star
  include ActiveDocument::Document
  include ActiveDocument::Timestamps

  embedded_in :galaxy, touch: true

  field :age, type: :integer
  field :was_touched_after_parent, type: :boolean, default: false

  before_validation :set_age

  embeds_many :planets

  set_callback(:touch, :before) do
    self.was_touched_after_parent = true if galaxy.was_touched
  end

  private

  def set_age
    self.age ||= 42_000
  end
end

class Planet
  include ActiveDocument::Document
  include ActiveDocument::Timestamps

  embedded_in :star, touch: true

  field :age, type: :integer
  field :was_touched_after_parent, type: :boolean, default: false

  before_validation :set_age

  set_callback(:touch, :before) do
    self.was_touched_after_parent = true if star.was_touched_after_parent
  end

  private

  def set_age
    self.age ||= 2_000
  end
end

class Emission
  include ActiveDocument::Document

  field :frequency

  after_save do
    @previous = attribute_was(:frequency)
  end

  attr_reader :previous
end

class Country
  include ActiveDocument::Document

  field :age

  before_validation :set_age

  embeds_one :president

  private

  def set_age
    self.age ||= 245
  end
end

class President
  include ActiveDocument::Document

  embedded_in :country

  field :age

  field :name

  before_validation :set_age

  embeds_one :first_spouse

  private

  def set_age
    self.age ||= 79
  end
end

class FirstSpouse
  include ActiveDocument::Document

  embedded_in :president

  field :name
  field :age, type: :integer

  before_validation :set_age

  private

  def set_age
    self.age ||= 70
  end
end

class Architect
  include ActiveDocument::Document

  has_and_belongs_to_many :buildings, after_add: :after_add_callback,
                                      after_remove: :after_remove_callback, dependent: :nullify

  field :after_add_num_buildings, type: :integer
  field :after_remove_num_buildings, type: :integer

  def after_add_callback(_obj)
    self.after_add_num_buildings = buildings.length
  end

  def after_remove_callback(_obj)
    self.after_remove_num_buildings = buildings.length
  end
end

class Building
  include ActiveDocument::Document

  has_and_belongs_to_many :architects, dependent: :nullify
end

class Root
  include ActiveDocument::Document
  embeds_many :embedded_once, cascade_callbacks: true
  after_save :trace

  attr_accessor :logger

  def trace
    logger << :root
  end
end

class EmbeddedOnce
  include ActiveDocument::Document
  embeds_many :embedded_twice, cascade_callbacks: true
  embedded_in :root
  after_save :trace

  attr_accessor :logger

  def trace
    logger << :embedded_once
  end
end

class EmbeddedTwice
  include ActiveDocument::Document
  embedded_in :embedded_once
  after_save :trace

  attr_accessor :logger

  def trace
    logger << :embedded_twice
  end
end
