# frozen_string_literal: true

class Product
  include ActiveDocument::Document
  field :description, localize: true
  field :name, localize: true, default: 'no translation'
  field :price, type: :integer
  field :brand_name
  field :stores, type: :array
  field :website, localize: true
  field :sku, as: :stock_keeping_unit
  field :tl, as: :tagline, localize: true
  field :title, localize: :present
  alias_attribute :cost, :price

  validates :name, presence: true
  validates :website, format: { with: URI::DEFAULT_PARSER.make_regexp, allow_blank: true }

  embeds_one :seo, as: :seo_tags, cascade_callbacks: true, autobuild: true
end
