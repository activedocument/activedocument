# frozen_string_literal: true

class User
  include ActiveDocument::Document

  field :name
  field :last_login, type: :date_time
  field :account_expires, type: :date

  has_one :account, foreign_key: :creator_id, validate: false
  has_many :posts, foreign_key: :author_id, validate: false
  has_many :descriptions
  has_one :role, validate: false

  has_and_belongs_to_many :followed_shops, inverse_of: :followers, class_name: 'Shop'
  has_and_belongs_to_many :businesses, class_name: 'Business', validate: false
  has_one :shop

  belongs_to :next, class_name: 'User'

  accepts_nested_attributes_for :posts
  index name: 1
end
