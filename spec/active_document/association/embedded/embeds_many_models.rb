# frozen_string_literal: true

class EmmCongress
  include ActiveDocument::Document
  include ActiveDocument::Timestamps

  embeds_many :legislators, class_name: 'EmmLegislator'

  field :name, type: :string
end

class EmmLegislator
  include ActiveDocument::Document

  embedded_in :congress, class_name: 'EmmCongress'

  field :a, type: :integer, default: 0
  field :b, type: :integer, default: 0
end

# Models with associations with :class_name as a :: prefixed string

class EmmCcCongress
  include ActiveDocument::Document

  embeds_many :legislators, class_name: '::EmmCcLegislator'

  field :name, type: :string
end

class EmmCcLegislator
  include ActiveDocument::Document

  embedded_in :congress, class_name: '::EmmCcCongress'

  field :a, type: :integer, default: 0
  field :b, type: :integer, default: 0
end

class EmmManufactory
  include ActiveDocument::Document

  embeds_many :products, order: :id.desc, class_name: 'EmmProduct'
end

class EmmProduct
  include ActiveDocument::Document

  embedded_in :manufactory, class_name: 'EmmManufactory'

  field :name, type: :string
end

class EmmInner
  include ActiveDocument::Document

  embeds_many :friends, class_name: name, cyclic: true
  embedded_in :parent, class_name: name, cyclic: true

  field :level, type: :integer
end

class EmmOuter
  include ActiveDocument::Document
  embeds_many :inners, class_name: 'EmmInner'

  field :level, type: :integer
end

class EmmCustomerAddress
  include ActiveDocument::Document

  embedded_in :addressable, polymorphic: true, inverse_of: :work_address
end

class EmmFriend
  include ActiveDocument::Document

  embedded_in :befriendable, polymorphic: true
end

class EmmCustomer
  include ActiveDocument::Document

  embeds_one :home_address, class_name: 'EmmCustomerAddress', as: :addressable
  embeds_one :work_address, class_name: 'EmmCustomerAddress', as: :addressable

  embeds_many :close_friends, class_name: 'EmmFriend', as: :befriendable
  embeds_many :acquaintances, class_name: 'EmmFriend', as: :befriendable
end

class EmmUser
  include ActiveDocument::Document
  include ActiveDocument::Timestamps

  embeds_many :orders, class_name: 'EmmOrder'
end

class EmmOrder
  include ActiveDocument::Document

  field :sku
  field :amount, type: :integer

  embedded_in :user, class_name: 'EmmUser'

  embeds_many :surcharges, class_name: 'EmmSurcharge'
end

class EmmSurcharge
  include ActiveDocument::Document

  field :sku
  field :amount, type: :integer

  embedded_in :order, class_name: 'EmmOrder'
end

module EmmSpec
  # There is also a top-level Car class defined.
  class Car
    include ActiveDocument::Document

    embeds_many :doors
  end

  class Door
    include ActiveDocument::Document

    embedded_in :car
  end

  class Tank
    include ActiveDocument::Document

    embeds_many :guns
    embeds_many :emm_turrets
    # This association references a model that is not in our module,
    # and it does not define class_name hence ActiveDocument will not be able to
    # figure out the inverse for this association.
    embeds_many :emm_hatches

    # class_name is intentionally unqualified, references a class in the
    # same module. Rails permits class_name to be unqualified like this.
    embeds_many :launchers, class_name: 'Launcher'
  end

  class Gun
    include ActiveDocument::Document

    embedded_in :tank
  end

  class Launcher
    include ActiveDocument::Document

    # class_name is intentionally unqualified.
    embedded_in :tank, class_name: 'Tank'
  end
end

# This is intentionally on top level.
class EmmTurret
  include ActiveDocument::Document

  embedded_in :tank, class_name: 'EmmSpec::Tank'
end

# This is intentionally on top level.
class EmmHatch
  include ActiveDocument::Document

  # No :class_name option on this association intentionally.
  # Also, re: MONGOID-5016, `touch: true` is the default, which means ActiveDocument
  # will try to load the associated class in order to add relevant callbacks.
  # We must set `touch: false` here to avoid ActiveDocument trying to load a
  # non-existent class.
  embedded_in :tank, touch: false
end

class EmmPost
  include ActiveDocument::Document

  embeds_many :company_tags, class_name: 'EmmCompanyTag'
  embeds_many :user_tags, class_name: 'EmmUserTag'
end

class EmmCompanyTag
  include ActiveDocument::Document

  field :title, type: :string

  embedded_in :post, class_name: 'EmmPost'
end

class EmmUserTag
  include ActiveDocument::Document

  field :title, type: :string

  embedded_in :post, class_name: 'EmmPost'
end

class EmmSchool
  include ActiveDocument::Document

  embeds_many :students, class_name: 'EmmStudent'

  field :name, type: :string

  validates :name, presence: true
end

class EmmStudent
  include ActiveDocument::Document

  embedded_in :school, class_name: 'EmmSchool'
end

class EmmParent
  include ActiveDocument::Document
  embeds_many :blocks, class_name: 'EmmBlock'
end

class EmmBlock
  include ActiveDocument::Document
  field :name, type: :string
  embeds_many :children, class_name: 'EmmChild'
end

class EmmChild
  include ActiveDocument::Document
  embedded_in :block, class_name: 'EmmBlock'

  field :size, type: :integer
  field :order, type: :integer
  field :t
end
