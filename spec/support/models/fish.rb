# frozen_string_literal: true

class Fish
  include ActiveDocument::Document

  def self.fresh
    where(fresh: true)
  end
end
