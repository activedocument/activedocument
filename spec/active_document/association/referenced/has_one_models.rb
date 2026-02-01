# frozen_string_literal: true
# rubocop:todo all

class HomCollege
  include ActiveDocument::Document

  has_one :accreditation, class_name: 'HomAccreditation'

  # The address is added with different dependency mechanisms in tests:
  #has_one :address, class_name: 'HomAddress', dependent: :destroy

  field :state, type: String
end

class HomAccreditation
  include ActiveDocument::Document

  belongs_to :college, class_name: 'HomCollege'

  field :degree, type: String
  field :year, type: Integer, default: 2012

  def format
    'fmt'
  end

  def price
    42
  end
end

class HomAccreditation::Child
  include ActiveDocument::Document

  belongs_to :hom_college
end

class HomAddress
  include ActiveDocument::Document

  belongs_to :college, class_name: 'HomCollege'
end

module HomNs
  class PrefixedParent
    include ActiveDocument::Document

    has_one :child, class_name: 'PrefixedChild'
  end

  class PrefixedChild
    include ActiveDocument::Document

    belongs_to :parent, class_name: 'PrefixedParent'
  end
end

class HomPolymorphicParent
  include ActiveDocument::Document

  has_one :p_child, as: :parent
end

class HomPolymorphicChild
  include ActiveDocument::Document

  belongs_to :p_parent, polymorphic: true
end

class HomBus
  include ActiveDocument::Document

  has_one :driver, class_name: 'HomBusDriver'
end

class HomBusDriver
  include ActiveDocument::Document

  # No belongs_to :bus
end

class HomTrainer
  include ActiveDocument::Document

  field :name, type: String

  has_one :animal, class_name: 'HomAnimal', scope: :reptile
end

class HomAnimal
  include ActiveDocument::Document

  field :taxonomy, type: String

  scope :reptile, -> { where(taxonomy: 'reptile') }

  belongs_to :trainer, class_name: 'HomTrainer', scope: -> { where(name: 'Dave') }
end

class HomPost
  include ActiveDocument::Document

  field :title, type: String

  has_one :comment, as: :container, class_name: 'HomComment'

  accepts_nested_attributes_for :comment, allow_destroy: true
end

class HomComment
  include ActiveDocument::Document

  field :content, type: String
  field :num, type: Integer, default: 0

  validates :num, numericality: { greater_than_or_equal_to: 0 }

  belongs_to :container, polymorphic: true, optional: true
  has_one :comment, as: :container, class_name: 'HomComment'

  accepts_nested_attributes_for :comment, allow_destroy: true
end
