# frozen_string_literal: true

class Student
  include ActiveDocument::Document

  belongs_to :school

  field :name, type: String
  field :grade, type: Integer, default: 3

  after_destroy do
    school.after_destroy_triggered = true if school
  end
end
