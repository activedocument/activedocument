class Post
  include Mongoid::Document
  include Mongoid::Timestamps
  field :subject, type: String
  field :message, type: String

  index subject: 1
end
