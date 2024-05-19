# frozen_string_literal: true

class BTMArticle
  include ActiveDocument::Document
  has_many :comments, class_name: 'BTMComment'
end

class BTMComment
  include ActiveDocument::Document
  belongs_to :article, class_name: 'BTMArticle', optional: true
end
