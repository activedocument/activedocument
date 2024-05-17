# frozen_string_literal: true

class SystemRole
  include ActiveDocument::Document

  # NOTE: this model is for test purposes only. It is not recommended that you
  # store ActiveDocument documents in system collections.
  store_in collection: 'system.roles', database: 'admin'
end
