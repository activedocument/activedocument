# frozen_string_literal: true

class Favorite
  include ActiveDocument::Document
  field :title
  validates_uniqueness_of :title, case_sensitive: false

  # See MONGOID-5016. The default for `touch` is now `true` for embedded_in
  # associations, which causes the referenced class to be loaded eagerly so
  # the relevant callbacks can be added. As `perp` is not a real class, we
  # need to explicitly set `touch: false` here, to avoid ActiveDocument trying to
  # load it.
  embedded_in :perp, touch: false, inverse_of: :favorites
end
