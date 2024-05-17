# frozen_string_literal: true

class CallbackTest
  include ActiveDocument::Document
  around_save :execute

  def execute
    yield(self)
    true
  end
end
