class Comment
  include ActiveDocument::Document
  include ActiveDocument::Timestamps
  belongs_to :post
end
