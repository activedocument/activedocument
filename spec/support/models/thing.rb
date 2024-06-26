# frozen_string_literal: true

class Thing
  include ActiveDocument::Document
  before_destroy :dont_do_it
  embedded_in :actor

  def dont_do_it
    throw(:abort)
  end
end
