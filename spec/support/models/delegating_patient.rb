# frozen_string_literal: true

class DelegatingPatient
  include ActiveDocument::Document

  embeds_one :email

  # Instance level delegation
  delegate :address, to: :email

  class << self
    # Class level delegation
    delegate :default_client, to: ::ActiveDocument
  end
end
