# frozen_string_literal: true

require 'singleton'

class ClientRegistry
  include Singleton

  def global_client(_name)
    ActiveDocument.default_client
  end
end
