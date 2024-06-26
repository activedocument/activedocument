# frozen_string_literal: true

class ParentDoc
  include ActiveDocument::Document
  field :statistic
  field :children_order, type: :array, default: [] # hold all the children's id
  embeds_many :children, class_name: 'ChildDoc', inverse_of: :parent_doc
end
