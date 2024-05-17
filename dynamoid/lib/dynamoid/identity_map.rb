# frozen_string_literal: true

module Dynamoid
  module IdentityMap
    extend ActiveSupport::Concern

    def self.clear
      Dynamoid.included_models.each { |m| m.identity_map.clear }
    end

    module ClassMethods
      def identity_map
        @identity_map ||= {}
      end

      # @private
      def from_database(attrs = {})
        return super if identity_map_off?

        key = identity_map_key(attrs)
        document = identity_map[key]

        if document.nil?
          document = super
          identity_map[key] = document
        else
          document.load(attrs)
        end

        document
      end

      # @private
      def find_by_id(id, options = {})
        return super if identity_map_off?

        key = id.to_s

        if range_key = options[:range_key]
          key += "::#{range_key}"
        end

        identity_map[key] || super
      end

      # @private
      def identity_map_key(attrs)
        key = attrs[hash_key].to_s
        key += "::#{attrs[range_key]}" if range_key
        key
      end

      def identity_map_on?
        Dynamoid::Config.identity_map
      end

      def identity_map_off?
        !identity_map_on?
      end
    end

    def identity_map
      self.class.identity_map
    end

    # @private
    def save(*args)
      return super if self.class.identity_map_off?

      if result = super
        identity_map[identity_map_key] = self
      end
      result
    end

    # @private
    def delete
      return super if self.class.identity_map_off?

      identity_map.delete(identity_map_key)
      super
    end

    # @private
    def identity_map_key
      key = hash_key.to_s
      key += "::#{range_value}" if self.class.range_key
      key
    end
  end
end
