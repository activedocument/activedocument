# frozen_string_literal: true

class Eye
  include ActiveDocument::Document

  field :pupil_dilation, type: :integer

  belongs_to :eyeable, polymorphic: true

  belongs_to :suspended_in, polymorphic: true
end
