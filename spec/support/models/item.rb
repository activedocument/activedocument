# frozen_string_literal: true

class Item
  include ActiveDocument::Document
  field :title, type: String
  field :is_rss, type: ActiveDocument::Boolean, default: false
  field :user_login, type: String
end

require 'support/models/sub_item'
