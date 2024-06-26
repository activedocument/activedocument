# frozen_string_literal: true

class Implant
  include ActiveDocument::Document

  field :name
  field :impressions, type: :integer, default: 0

  embedded_in :player, inverse_of: :implants

  after_build do |doc|
    doc.name = "Cochlear Implant (#{player.frags})"
  end

  field :after_find_player
  field :after_initialize_player
  field :after_default_player, default: -> { player&._id }

  after_find do |doc|
    doc.impressions += 1
    doc.after_find_player = player&._id
  end

  after_initialize do |doc|
    doc.after_initialize_player = player&._id
  end
end
