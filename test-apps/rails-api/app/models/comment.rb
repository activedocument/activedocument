class Comment
  include Mongoid::Document
  include Mongoid::Timestamps
  belongs_to :post
end
