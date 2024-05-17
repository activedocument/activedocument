# frozen_string_literal: true

class SmMovie
  include ActiveDocument::Document

  field :year, type: Integer

  index year: 1
  shard_key :year
end

class SmTrailer
  include ActiveDocument::Document

  index year: 1
  shard_key 'year'
end

class SmActor
  include ActiveDocument::Document

  # This is not a usable shard configuration for the server.
  # We just have it for unit tests.
  shard_key age: 1, 'gender' => :hashed, 'hello' => :hashed
end

class SmAssistant
  include ActiveDocument::Document

  field :gender, type: String

  index gender: 1
  shard_key 'gender' => :hashed
end

class SmProducer
  include ActiveDocument::Document

  index age: 1, gender: 1
  shard_key({ age: 1, gender: 'hashed' }, unique: true, numInitialChunks: 2)
end

class SmDirector
  include ActiveDocument::Document

  belongs_to :agency

  index age: 1
  shard_key :agency
end

class SmDriver
  include ActiveDocument::Document

  belongs_to :agency

  index age: 1, agency: 1
  shard_key age: 1, agency: :hashed
end

class SmNotSharded
  include ActiveDocument::Document
end

class SmReviewAuthor
  include ActiveDocument::Document
  embedded_in :review, class_name: 'SmReview', touch: false
  field :name, type: String
end

class SmReview
  include ActiveDocument::Document

  embeds_one :author, class_name: 'SmReviewAuthor'

  shard_key 'author.name' => 1
end
