# frozen_string_literal: true

require 'singleton'

class ClientRegistry
  include Singleton

  def global_client(name)
    Mongoid.default_client
  end
end
