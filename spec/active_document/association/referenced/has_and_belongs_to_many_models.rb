# frozen_string_literal: true

class HabtmmCompany
  include ActiveDocument::Document

  field :c_id, type: :integer
  field :e_ids, type: :array
  has_and_belongs_to_many :employees, class_name: 'HabtmmEmployee',
                                      primary_key: :e_id, foreign_key: :e_ids,
                                      inverse_primary_key: :c_id, inverse_foreign_key: :c_ids
end

class HabtmmEmployee
  include ActiveDocument::Document

  field :e_id, type: :integer
  field :c_ids, type: :array
  field :habtmm_company_ids, type: :array
  has_and_belongs_to_many :companies, class_name: 'HabtmmCompany',
                                      primary_key: :c_id, foreign_key: :c_ids,
                                      inverse_primary_key: :e_id, inverse_foreign_key: :e_ids
end

class HabtmmContract
  include ActiveDocument::Document

  has_and_belongs_to_many :signatures, class_name: 'HabtmmSignature'

  field :item, type: :string
end

class HabtmmSignature
  include ActiveDocument::Document

  field :favorite_signature, default: -> { contracts.first&.signature_ids&.first }

  has_and_belongs_to_many :contracts, class_name: 'HabtmmContract'

  field :name, type: :string
  field :year, type: :integer
end

class HabtmmTicket
  include ActiveDocument::Document
end

class HabtmmPerson
  include ActiveDocument::Document

  has_and_belongs_to_many :tickets, class_name: 'HabtmmTicket'
end

class HabtmmTrainer
  include ActiveDocument::Document

  field :name, type: :string

  has_and_belongs_to_many :animals, inverse_of: :trainers, class_name: 'HabtmmAnimal', scope: :reptile
end

class HabtmmAnimal
  include ActiveDocument::Document

  field :taxonomy, type: :string

  scope :reptile, -> { where(taxonomy: 'reptile') }

  has_and_belongs_to_many :trainers, inverse_of: :animals, class_name: 'HabtmmTrainer', scope: -> { where(name: 'Dave') }
end

class HabtmmSchool
  include ActiveDocument::Document
  include ActiveDocument::Timestamps

  has_and_belongs_to_many :students, class_name: 'HabtmmStudent'

  field :after_destroy_triggered, default: false

  accepts_nested_attributes_for :students, allow_destroy: true
end

class HabtmmStudent
  include ActiveDocument::Document
  include ActiveDocument::Timestamps

  has_and_belongs_to_many :schools, class_name: 'HabtmmSchool'

  after_destroy do
    schools.first.update!(after_destroy_triggered: true) unless schools.empty?
  end
end
