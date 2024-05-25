# frozen_string_literal: true

class Profile
  include ActiveDocument::Document
  field :name, type: :string

  embeds_one :profile_image

  shard_key :name
end

class ProfileImage
  include ActiveDocument::Document
  field :url, type: :string

  embedded_in :profile
end
