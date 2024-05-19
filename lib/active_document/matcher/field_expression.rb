# frozen_string_literal: true

module ActiveDocument
  module Matcher

    # Singleton module used for evaluating whether a given
    # value in-memory matches an MSQL query expression related
    # to a specific field.
    #
    # @api private
    module FieldExpression

      extend self

      # @api private
      DOLLAR_REGEX_OPTIONS = %w[$regex $options].freeze

      # Returns whether a value satisfies a condition.
      #
      # @param [ true | false ] exists Whether the value exists.
      # @param [ Object ] value The value to check.
      # @param [ Hash | Object ] condition The condition predicate.
      #
      # @return [ true | false ] Whether the value matches.
      #
      # @api private
      def matches?(exists, value, condition)
        if condition.is_a?(Hash)
          condition.all? do |k, cond_v|
            k = k.to_s
            if k.start_with?('$')
              if DOLLAR_REGEX_OPTIONS.include?(k)
                unless condition.key?('$regex')
                  raise Errors::InvalidQuery.new("$regex is required if $options is given: #{Errors::InvalidQuery.truncate_expr(condition)}")
                end

                if k == '$regex'
                  if (options = condition['$options'])
                    cond_v = case cond_v
                             when Regexp
                               BSON::Regexp::Raw.new(cond_v.source, options)
                             when BSON::Regexp::Raw
                               BSON::Regexp::Raw.new(cond_v.pattern, options)
                             else
                               BSON::Regexp::Raw.new(cond_v, options)
                             end
                  elsif cond_v.is_a?(String)
                    cond_v = BSON::Regexp::Raw.new(cond_v)
                  end

                  FieldOperator.get(k).matches?(exists, value, cond_v)
                else
                  # $options are matched as part of $regex
                  true
                end
              else
                FieldOperator.get(k).matches?(exists, value, cond_v)
              end
            elsif value.is_a?(Hash)
              sub_values = Matcher.extract_attribute(value, k)
              if sub_values.empty?
                Eq.matches?(false, nil, cond_v)
              else
                sub_values.any? do |sub_v|
                  Eq.matches?(true, sub_v, cond_v)
                end
              end
            else
              false
            end
          end
        else
          case condition
          when ::Regexp, BSON::Regexp::Raw
            Regex.matches_array_or_scalar?(value, condition)
          else
            Eq.matches?(exists, value, condition)
          end
        end
      end
    end
  end
end
