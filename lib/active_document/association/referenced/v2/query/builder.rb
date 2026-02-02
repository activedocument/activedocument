# frozen_string_literal: true

module ActiveDocument
  module Association
    module Referenced
      module V2
        module Query
          # Builds criteria for querying associated documents.
          # Handles different query patterns based on association type.
          class Builder
            attr_reader :association

            # @param association [Association] The association this builder belongs to
            def initialize(association)
              @association = association
            end

            # Build criteria for belongs_to associations.
            # Queries the target class by primary key using the stored foreign key value.
            #
            # @param object [Object] The foreign key value (ID)
            # @param type [Class, String, nil] The polymorphic type class
            # @return [ActiveDocument::Criteria]
            def criteria_by_primary_key(object, type = nil)
              return nil if object.nil?

              cls = resolve_class(type)
              crit = cls.criteria
              crit = apply_scope(crit)
              crit.where(association.primary_key => object)
            end

            # Build criteria for has_one/has_many associations.
            # Queries the target class by foreign key matching the base's primary key.
            #
            # @param base [ActiveDocument::Document] The owning document
            # @return [ActiveDocument::Criteria]
            def criteria_by_foreign_key(base)
              pk_value = base.public_send(association.primary_key)
              crit = target_class.criteria
              crit = apply_scope(crit)
              crit = crit.where(association.foreign_key => pk_value)
              crit = with_polymorphic_criterion(crit, base)
              crit = with_ordering(crit)
              configure_criteria(crit, base)
            end

            # Build criteria for belongs_to_many associations.
            # Queries the target class by primary key matching the stored array of IDs.
            #
            # @param base [ActiveDocument::Document] The owning document
            # @param id_list [Array, nil] Optional explicit list of IDs
            # @return [ActiveDocument::Criteria]
            def criteria_by_id_list(base, id_list = nil)
              ids = id_list || base.public_send(association.foreign_key)

              crit = target_class.criteria
              crit = if ids.present?
                       crit = apply_scope(crit)
                       crit.all_of(association.primary_key => { '$in' => ids })
                     else
                       crit.none
                     end
              with_ordering(crit)
            end

            private

            def target_class
              association.relation_class
            end

            def resolve_class(type)
              return target_class unless type

              case type
              when String then type.constantize
              when Class then type
              else type
              end
            end

            def apply_scope(criteria)
              scope = association.options.scope
              return criteria unless scope

              criteria.apply_scope(scope)
            end

            def with_ordering(criteria)
              order = association.options.order
              order ? criteria.order_by(order) : criteria
            end

            def with_polymorphic_criterion(criteria, base)
              return criteria unless association.type

              criteria.where(association.type => base.class.name)
            end

            def configure_criteria(criteria, base)
              criteria.association = association
              criteria.parent_document = base
              criteria
            end
          end
        end
      end
    end
  end
end
