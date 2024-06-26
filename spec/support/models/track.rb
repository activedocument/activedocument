# frozen_string_literal: true

class Track
  include ActiveDocument::Document
  field :name, type: :string

  field :before_create_called, type: :boolean, default: false
  field :before_save_called, type: :boolean, default: false
  field :before_update_called, type: :boolean, default: false
  field :before_validation_called, type: :boolean, default: false
  field :before_destroy_called, type: :boolean, default: false

  embedded_in :record

  before_create :before_create_stub
  before_save :before_save_stub
  before_update :before_update_stub
  before_validation :before_validation_stub
  before_destroy :before_destroy_stub

  def before_create_stub
    self.before_create_called = true
  end

  def before_save_stub
    self.before_save_called = true
  end

  def before_update_stub
    self.before_update_called = true
  end

  def before_validation_stub
    self.before_validation_called = true
  end

  def before_destroy_stub
    self.before_destroy_called = true
  end
end
