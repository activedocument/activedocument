# frozen_string_literal: true

module ReversePopulationSpec
  class Company
    include ActiveDocument::Document

    has_many :emails, class_name: 'ReversePopulationSpec::Email'
    has_one :founder, class_name: 'ReversePopulationSpec::Founder'
  end

  class Email
    include ActiveDocument::Document

    belongs_to :company, class_name: 'ReversePopulationSpec::Company'
  end

  class Founder
    include ActiveDocument::Document

    belongs_to :company, class_name: 'ReversePopulationSpec::Company'
  end

  class Animal
    include ActiveDocument::Document

    field :a, type: :string
    has_and_belongs_to_many :zoos, class_name: 'ReversePopulationSpec::Zoo'
  end

  class Zoo
    include ActiveDocument::Document

    field :z, type: :string
    has_and_belongs_to_many :animals, class_name: 'ReversePopulationSpec::Animal'
  end
end
