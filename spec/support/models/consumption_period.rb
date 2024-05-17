# frozen_string_literal: true

class ConsumptionPeriod
  include ActiveDocument::Document

  belongs_to :account

  field :started_at, type: Time
end
