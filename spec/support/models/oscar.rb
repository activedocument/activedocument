# frozen_string_literal: true

class Oscar
  include ActiveDocument::Document
  field :title, type: String
  field :destroy_after_save, type: ActiveDocument::Boolean, default: false
  before_save :complain

  def complain
    if destroy_after_save?
      destroy
    else
      throw(:abort)
    end
  end
end
