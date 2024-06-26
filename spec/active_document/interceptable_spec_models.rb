# frozen_string_literal: true

module InterceptableSpec
  class CallbackRegistry
    def initialize
      @calls = []
    end

    def record_call(klass, callback)
      @calls << [klass, callback]
    end

    attr_reader :calls
  end

  module CallbackTracking
    extend ActiveSupport::Concern

    included do
      whens = %i[before after]
      %i[validation save create update].each do |what|
        whens.each do |whn|
          send(:"#{whn}_#{what}", :"#{whn}_#{what}_stub")
          define_method(:"#{whn}_#{what}_stub") do
            callback_registry&.record_call(self.class, :"#{whn}_#{what}")
          end
        end
        next if what == :validation

        send(:"around_#{what}", :"around_#{what}_stub")
        define_method(:"around_#{what}_stub") do |&block|
          callback_registry&.record_call(self.class, :"around_#{what}_open")
          block.call
          callback_registry&.record_call(self.class, :"around_#{what}_close")
        end
      end
    end
  end

  class CbHasOneParent
    include ActiveDocument::Document

    has_one :child, autosave: true, class_name: 'CbHasOneChild', inverse_of: :parent

    def initialize(callback_registry)
      @callback_registry = callback_registry
      super()
    end

    attr_accessor :callback_registry

    def insert_as_root
      @callback_registry&.record_call(self.class, :insert_into_database)
      super
    end

    include CallbackTracking
  end

  class CbHasOneChild
    include ActiveDocument::Document

    belongs_to :parent, class_name: 'CbHasOneParent', inverse_of: :child

    def initialize(callback_registry)
      @callback_registry = callback_registry
      super()
    end

    attr_accessor :callback_registry

    include CallbackTracking
  end

  class CbHasManyParent
    include ActiveDocument::Document

    has_many :children, autosave: true, class_name: 'CbHasManyChild', inverse_of: :parent

    def initialize(callback_registry)
      @callback_registry = callback_registry
      super()
    end

    attr_accessor :callback_registry

    def insert_as_root
      @callback_registry&.record_call(self.class, :insert_into_database)
      super
    end

    include CallbackTracking
  end

  class CbHasManyChild
    include ActiveDocument::Document

    belongs_to :parent, class_name: 'CbHasManyParent', inverse_of: :children

    def initialize(callback_registry)
      @callback_registry = callback_registry
      super()
    end

    attr_accessor :callback_registry

    include CallbackTracking
  end

  class CbEmbedsOneParent
    include ActiveDocument::Document

    field :name

    embeds_one :child, cascade_callbacks: true, class_name: 'CbEmbedsOneChild', inverse_of: :parent

    def initialize(callback_registry)
      @callback_registry = callback_registry
      super()
    end

    attr_accessor :callback_registry

    def insert_as_root
      @callback_registry&.record_call(self.class, :insert_into_database)
      super
    end

    include CallbackTracking
  end

  class CbEmbedsOneChild
    include ActiveDocument::Document

    field :age

    embedded_in :parent, class_name: 'CbEmbedsOneParent', inverse_of: :child

    def initialize(callback_registry)
      @callback_registry = callback_registry
      super()
    end

    attr_accessor :callback_registry

    include CallbackTracking
  end

  class CbEmbedsManyParent
    include ActiveDocument::Document

    embeds_many :children, cascade_callbacks: true, class_name: 'CbEmbedsManyChild', inverse_of: :parent

    def initialize(callback_registry)
      @callback_registry = callback_registry
      super()
    end

    attr_accessor :callback_registry

    def insert_as_root
      @callback_registry&.record_call(self.class, :insert_into_database)
      super
    end

    include CallbackTracking
  end

  class CbEmbedsManyChild
    include ActiveDocument::Document

    embedded_in :parent, class_name: 'CbEmbedsManyParent', inverse_of: :children

    def initialize(callback_registry)
      @callback_registry = callback_registry
      super()
    end

    attr_accessor :callback_registry

    include CallbackTracking
  end

  class CbParent
    include ActiveDocument::Document

    def initialize(callback_registry)
      @callback_registry = callback_registry
      super()
    end

    attr_accessor :callback_registry

    embeds_many :cb_children
    embeds_many :cb_cascaded_children, cascade_callbacks: true

    include CallbackTracking
  end

  class CbChild
    include ActiveDocument::Document

    embedded_in :cb_parent

    def initialize(callback_registry, options)
      @callback_registry = callback_registry
      super(options)
    end

    attr_accessor :callback_registry

    include CallbackTracking
  end

  class CbCascadedChild
    include ActiveDocument::Document

    embedded_in :cb_parent

    def initialize(callback_registry, options)
      @callback_registry = callback_registry
      super(options)
    end

    attr_accessor :callback_registry

    include CallbackTracking
  end
end

class InterceptableBand
  include ActiveDocument::Document

  has_many :songs, class_name: 'InterceptableSong'
  field :name
end

class InterceptableSong
  include ActiveDocument::Document

  belongs_to :band, class_name: 'InterceptableBand'
  field :band_name, default: -> { band.name }
  field :name
end

class InterceptablePlane
  include ActiveDocument::Document

  has_many :wings, class_name: 'InterceptableWing'
end

class InterceptableWing
  include ActiveDocument::Document

  belongs_to :plane, class_name: 'InterceptablePlane'
  has_one :engine, autobuild: true, class_name: 'InterceptableEngine'

  field :_id, type: :string, default: -> { 'hello-wing' }

  field :p_id, type: :string, default: -> { plane&.id }
  field :e_id, type: :string, default: -> { engine&.id }
end

class InterceptableEngine
  include ActiveDocument::Document

  belongs_to :wing, class_name: 'InterceptableWing'

  field :_id, type: :string, default: -> { "hello-engine-#{wing&.id}" }
end

class InterceptableCompany
  include ActiveDocument::Document

  has_many :users, class_name: 'InterceptableUser'
  has_many :shops, class_name: 'InterceptableShop'
end

class InterceptableShop
  include ActiveDocument::Document

  embeds_one :address, class_name: 'InterceptableAddress'
  belongs_to :company, class_name: 'InterceptableCompany'

  after_initialize :build_address1

  def build_address1
    self.address ||= Address.new
  end
end

class InterceptableAddress
  include ActiveDocument::Document
  embedded_in :shop, class_name: 'InterceptableShop'
end

class InterceptableUser
  include ActiveDocument::Document

  belongs_to :company, class_name: 'InterceptableCompany'

  validate :break_active_document

  def break_active_document
    company.shop_ids
  end
end
