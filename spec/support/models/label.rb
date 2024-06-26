# frozen_string_literal: true

class Label
  include ActiveDocument::Document
  include ActiveDocument::Timestamps::Updated::Short

  field :name, type: :string
  field :sales, type: :big_decimal
  field :age, type: :integer

  field :after_create_called, type: :boolean, default: false
  field :after_save_called, type: :boolean, default: false
  field :after_update_called, type: :boolean, default: false
  field :after_validation_called, type: :boolean, default: false

  field :before_save_count, type: :integer, default: 0

  embedded_in :artist
  embedded_in :band

  before_save :before_save_stub
  after_create :after_create_stub
  after_save :after_save_stub
  after_update :after_update_stub
  after_validation :after_validation_stub
  before_validation :cleanup

  def before_save_stub
    self.before_save_count += 1
  end

  def after_create_stub
    self.after_create_called = true
  end

  def after_save_stub
    self.after_save_called = true
  end

  def after_update_stub
    self.after_update_called = true
  end

  def after_validation_stub
    self.after_validation_called = true
  end

  private

  def cleanup
    self.name = name.downcase.capitalize if name
  end
end
