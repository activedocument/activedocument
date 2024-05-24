# frozen_string_literal: true

class HomCollege
  include ActiveDocument::Document

  has_one :accreditation, class_name: 'HomAccreditation'

  # The address is added with different dependency mechanisms in tests:
  # has_one :address, class_name: 'HomAddress', dependent: :destroy

  field :state, type: :string
end

class HomAccreditation
  include ActiveDocument::Document

  belongs_to :college, class_name: 'HomCollege'

  field :degree, type: :string
  field :year, type: :integer, default: 2012

  def format
    'fmt'
  end

  def price
    42
  end
end

class HomAccreditation
  class Child
    include ActiveDocument::Document

    belongs_to :hom_college
  end
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

  field :name, type: :string

  has_one :animal, class_name: 'HomAnimal', scope: :reptile
end

class HomAnimal
  include ActiveDocument::Document

  field :taxonomy, type: :string

  scope :reptile, -> { where(taxonomy: 'reptile') }

  belongs_to :trainer, class_name: 'HomTrainer', scope: -> { where(name: 'Dave') }
end

class HomPost
  include ActiveDocument::Document

  field :title, type: :string

  has_one :comment, inverse_of: :post, class_name: 'HomComment'
end

class HomComment
  include ActiveDocument::Document

  field :content, type: :string

  belongs_to :post, inverse_of: :comment, optional: true, class_name: 'HomPost'
end
