class Post
  include ActiveDocument::Document
  include ActiveDocument::Timestamps
  field :subject, type: :string
  field :message, type: :string

  index subject: 1
end
