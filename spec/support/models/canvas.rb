# frozen_string_literal: true

class Canvas
  include ActiveDocument::Document
  field :name
  embeds_many :shapes
  embeds_one :writer
  embeds_one :palette

  field :foo, type: :string, default: -> { 'original' }

  has_many :comments, as: :commentable

  accepts_nested_attributes_for :shapes
  accepts_nested_attributes_for :writer

  def render
    shapes.each { |_shape| render }
  end

  class Test < Canvas

    field :foo, type: :string, overwrite: true, default: -> { 'overridden' }
  end
end

require 'support/models/browser'
