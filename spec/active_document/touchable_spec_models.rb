# frozen_string_literal: true

module TouchableSpec
  module Embedded
    class Building
      include ActiveDocument::Document
      include ActiveDocument::Timestamps

      field :title, type: String

      embeds_many :entrances, class_name: 'TouchableSpec::Embedded::Entrance'
      embeds_many :floors, class_name: 'TouchableSpec::Embedded::Floor'
    end

    class Entrance
      include ActiveDocument::Document
      include ActiveDocument::Timestamps

      field :last_used_at, type: Time
      field :level, type: Integer

      embedded_in :building, touch: false, class_name: 'TouchableSpec::Embedded::Building'

      embeds_many :keypads, class_name: 'TouchableSpec::Embedded::Keypad'
      embeds_many :cameras, class_name: 'TouchableSpec::Embedded::Camera'
    end

    class Floor
      include ActiveDocument::Document
      include ActiveDocument::Timestamps

      field :level, type: Integer
      field :last_used_at, type: Time

      embedded_in :building, touch: true, class_name: 'TouchableSpec::Embedded::Building'

      embeds_many :chairs, class_name: 'TouchableSpec::Embedded::Chair'
      embeds_many :sofas, class_name: 'TouchableSpec::Embedded::Sofa'
    end

    class Keypad
      include ActiveDocument::Document
      include ActiveDocument::Timestamps

      embedded_in :entrance, touch: false, class_name: 'TouchableSpec::Embedded::Entrance'
    end

    class Camera
      include ActiveDocument::Document
      include ActiveDocument::Timestamps

      embedded_in :entrance, touch: true, class_name: 'TouchableSpec::Embedded::Entrance'
    end

    class Chair
      include ActiveDocument::Document
      include ActiveDocument::Timestamps

      embedded_in :floor, touch: false, class_name: 'TouchableSpec::Embedded::Floor'
    end

    class Sofa
      include ActiveDocument::Document
      include ActiveDocument::Timestamps

      embedded_in :floor, touch: true, class_name: 'TouchableSpec::Embedded::Floor'
    end
  end

  module Referenced
    class Building
      include ActiveDocument::Document
      include ActiveDocument::Timestamps

      has_many :entrances, inverse_of: :building, class_name: 'TouchableSpec::Referenced::Entrance'
      has_many :floors, inverse_of: :building, class_name: 'TouchableSpec::Referenced::Floor'
    end

    class Entrance
      include ActiveDocument::Document
      include ActiveDocument::Timestamps

      field :level, type: Integer

      belongs_to :building, touch: false, class_name: 'TouchableSpec::Referenced::Building'

      embeds_many :keypads, class_name: 'TouchableSpec::Referenced::Keypad'
      embeds_many :cameras, class_name: 'TouchableSpec::Referenced::Camera'

      has_many :plants, class_name: 'TouchableSpec::Referenced::Plant'
      has_many :windows, class_name: 'TouchableSpec::Referenced::Window'
    end

    class Floor
      include ActiveDocument::Document
      include ActiveDocument::Timestamps

      field :level, type: Integer

      belongs_to :building, touch: true, class_name: 'TouchableSpec::Referenced::Building'

      embeds_many :chairs, class_name: 'TouchableSpec::Referenced::Chair'
      embeds_many :sofas, class_name: 'TouchableSpec::Referenced::Sofa'

      has_many :plants, class_name: 'TouchableSpec::Referenced::Plant'
      has_many :windows, class_name: 'TouchableSpec::Referenced::Window'
    end

    class Plant
      include ActiveDocument::Document
      include ActiveDocument::Timestamps

      belongs_to :floor, touch: false, class_name: 'TouchableSpec::Referenced::Floor'
      belongs_to :entrance, touch: false, class_name: 'TouchableSpec::Referenced::Entrance'
    end

    class Window
      include ActiveDocument::Document
      include ActiveDocument::Timestamps

      belongs_to :floor, touch: true, class_name: 'TouchableSpec::Referenced::Floor'
      belongs_to :entrance, touch: true, class_name: 'TouchableSpec::Referenced::Entrance'
    end

    class Keypad
      include ActiveDocument::Document
      include ActiveDocument::Timestamps

      embedded_in :entrance, touch: false, class_name: 'TouchableSpec::Referenced::Entrance'
    end

    class Camera
      include ActiveDocument::Document
      include ActiveDocument::Timestamps

      embedded_in :entrance, touch: true, class_name: 'TouchableSpec::Referenced::Entrance'
    end

    class Chair
      include ActiveDocument::Document
      include ActiveDocument::Timestamps

      embedded_in :floor, touch: false, class_name: 'TouchableSpec::Referenced::Floor'
    end

    class Sofa
      include ActiveDocument::Document
      include ActiveDocument::Timestamps

      embedded_in :floor, touch: true, class_name: 'TouchableSpec::Referenced::Floor'
    end
  end
end
