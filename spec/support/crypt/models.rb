# frozen_string_literal: true

module Crypt
  class Patient
    include ActiveDocument::Document

    encrypt_with key_id: 'grolrnFVSSW9Gq04Q87R9Q=='

    field :code, type: :string
    field :medical_records, type: :array, encrypt: { deterministic: false }
    field :blood_type, type: :string, encrypt: {
      deterministic: false,
      key_name_field: :blood_type_key_name
    }
    field :ssn, type: :integer, encrypt: { deterministic: true }
    field :blood_type_key_name, type: :string

    embeds_one :insurance, class_name: 'Crypt::Insurance'
  end

  class Insurance
    include ActiveDocument::Document

    field :policy_number, type: :integer, encrypt: { deterministic: true }
    embedded_in :patient, class_name: 'Crypt::Patient'
  end

  class User
    include ActiveDocument::Document

    field :name, type: :string, encrypt: {
      key_id: 'grolrnFVSSW9Gq04Q87R9Q==',
      deterministic: false
    }
    field :email, type: :string, encrypt: {
      key_id: 'S34mE/HhSFSym3yErpER6Q==',
      deterministic: true
    }
  end

  class Car
    include ActiveDocument::Document

    store_in database: 'vehicles'

    encrypt_with key_id: 'grolrnFVSSW9Gq04Q87R9Q==', deterministic: true

    field :vin, type: :string, encrypt: true
    field :make, type: :string
  end
end
