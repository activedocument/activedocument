# frozen_string_literal: true

class EomParent
  include ActiveDocument::Document
  include ActiveDocument::Timestamps

  embeds_one :child, class_name: 'EomChild'

  field :name, type: :string
end

class EomChild
  include ActiveDocument::Document

  embedded_in :parent, class_name: 'EomParent'

  field :a, type: :integer, default: 0
  field :b, type: :integer, default: 0
end

# Models with associations with :class_name as a :: prefixed string

class EomCcParent
  include ActiveDocument::Document

  embeds_one :child, class_name: '::EomCcChild'
end

class EomCcChild
  include ActiveDocument::Document

  embedded_in :parent, class_name: '::EomCcParent'
end

# Models referencing other models which should not be loaded unless the
# respective association is referenced

autoload :EomDnlMissingChild, 'active_document/association/embedded/embeds_one_dnl_models'

class EomDnlParent
  include ActiveDocument::Document

  embeds_one :child, class_name: 'EomDnlChild'
  embeds_one :missing_child, class_name: 'EomDnlMissingChild'
end

autoload :EomDnlMissingParent, 'active_document/association/embedded/embeds_one_dnl_models'

class EomDnlChild
  include ActiveDocument::Document

  embedded_in :parent, class_name: 'EomDnlParent'

  # `touch: false` is necessary here because Touchable tries to reference the
  # associated class when it adds the callbacks for touching. See MONGOID-5016
  # re: `touch: true` as the default for embedded_in associations.
  embedded_in :missing_parent, touch: false, class_name: 'EomDnlMissingParent'
end

class EomAddress
  include ActiveDocument::Document

  field :city, type: :string

  embedded_in :addressable, polymorphic: true
end

# app/models/company.rb
class EomCompany
  include ActiveDocument::Document

  embeds_one :address, class_name: 'EomAddress', as: :addressable
  accepts_nested_attributes_for :address

  embeds_one :delivery_address, class_name: 'EomAddress', as: :addressable
  accepts_nested_attributes_for :delivery_address
end
