# frozen_string_literal: true

module CopyableSpec
  class A
    include ActiveDocument::Document

    embeds_many :locations
    embeds_many :influencers
  end

  class Location
    include ActiveDocument::Document

    embeds_many :buildings
  end

  class Building
    include ActiveDocument::Document
  end

  class Influencer
    include ActiveDocument::Document

    embeds_many :blurbs
  end

  class Youtuber < Influencer
  end

  class Blurb
    include ActiveDocument::Document
  end

  # Do not include Attributes::Dynamic
  class Reg
    include ActiveDocument::Document

    field :name, type: String
  end

  class Dyn
    include ActiveDocument::Document
    include ActiveDocument::Attributes::Dynamic

    field :name, type: String
  end
end
