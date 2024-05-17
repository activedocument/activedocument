class Post
  include ActiveDocument::Document
  include ActiveDocument::Timestamps
  field :subject, type: String
  field :message, type: String

  index subject: 1
end
