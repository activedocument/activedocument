# frozen_string_literal: true

class DrugAuto
  include Mongoid::Document
  field :name, type: String
  field :generic, type: Mongoid::Boolean
  belongs_to :person, class_name: 'PersonAuto', inverse_of: nil, counter_cache: true
end
