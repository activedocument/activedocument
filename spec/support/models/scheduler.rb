# frozen_string_literal: true

class Scheduler
  include ActiveDocument::Document

  def strategy
    Strategy.new
  end
end
