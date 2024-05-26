# frozen_string_literal: true

class Birthday
  include ActiveDocument::Document
  field :title
  field :date, type: :date
  embedded_in :owner, inverse_of: :birthdays

  def self.each_day(start_date, end_date, &block)
    groups = only(:date).asc(:date).where(date: { '$gte' => start_date, '$lte' => end_date }).group
    groups.each(&block)
  end
end
