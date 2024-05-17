module ActiveDocument
  module Adapters
    module Abstract
      class Features

        def use_transactions?
          false
        end

        def use_atomic_operations?
          false
        end

        def use_indexes?
          false
        end

        def use_field_level_encryption?
          false
        end
      end
    end
  end
end