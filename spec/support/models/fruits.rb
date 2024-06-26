# frozen_string_literal: true

module Fruits
  class Apple
    include ActiveDocument::Document
    has_many :bananas, class_name: 'Fruits::Banana'
    has_many :fruits_melons, class_name: 'Fruits::Melon'
    recursively_embeds_many
  end

  class Banana
    include ActiveDocument::Document
    belongs_to :apple, class_name: 'Fruits::Apple'
  end

  class Melon
    include ActiveDocument::Document
    belongs_to :fruit_apple, class_name: 'Fruits::Apple'
  end

  class Pineapple
    include ActiveDocument::Document
    recursively_embeds_many cascade_callbacks: true
  end

  class Mango
    include ActiveDocument::Document
    recursively_embeds_one cascade_callbacks: true
  end

  module Big
    class Ananas
      include ActiveDocument::Document
    end
  end
end
