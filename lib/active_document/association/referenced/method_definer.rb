# frozen_string_literal: true

module ActiveDocument
  module Association
    module Referenced
      # Defines accessor methods on the owning class for associations.
      # Uses the existing Accessors and Builders modules where possible.
      class MethodDefiner
        attr_reader :association

        # @param association [Association] The association to define methods for
        def initialize(association)
          @association = association
        end

        # Define all required methods for the association.
        def define_all!
          define_getter!
          define_setter!
          define_existence_check!

          if association.one?
            define_builder!
            define_creator!
            # Note: For belongs_to_one, the foreign key field creates the _id accessor.
            # We don't need separate _id getter/setter methods.
          elsif association.association_type == :has_many
            # Only define _ids accessors for has_many.
            # For belongs_to_many, the foreign key field already provides _ids accessor.
            define_ids_getter!
            define_ids_setter!
          end
        end

        private

        def owner_class
          association.owner_class
        end

        def name
          association.name
        end

        # Define the getter method: person.posts
        def define_getter!
          assoc = association
          owner_class.re_define_method(name) do |reload = false|
            value = get_relation(assoc.name, assoc, nil, reload)
            if value.nil? && assoc.autobuilding? && !without_autobuild?
              value = send(:"build_#{assoc.name}")
            end
            value
          end
        end

        # Define the setter method: person.posts = [...]
        def define_setter!
          assoc = association
          owner_class.re_define_method("#{name}=") do |object|
            without_autobuild do
              if (value = get_relation(assoc.name, assoc, object))
                unless value.respond_to?(:substitute)
                  value = __build__(assoc.name, value, assoc)
                end
                set_relation(assoc.name, value.substitute(object.substitutable))
              else
                __build__(assoc.name, object.substitutable, assoc)
              end
            end
          end
        end

        # Define existence check: person.posts?, person.has_posts?
        def define_existence_check!
          assoc = association
          owner_class.module_eval(
            <<-METHOD, __FILE__, __LINE__ + 1
              def #{name}?
                without_autobuild { !__send__(:#{name}).blank? }
              end
              alias :has_#{name}? :#{name}?
            METHOD
          )
        end

        # Define builder for single associations: person.build_account
        def define_builder!
          assoc = association
          owner_class.re_define_method("build_#{name}") do |*args|
            attributes, _options = parse_args(*args)
            document = Factory.build(assoc.relation_class, attributes)
            _building do
              send(:"#{assoc.name}=", document)
              document.run_callbacks(:build)
              document
            end
          end
        end

        # Define creator for single associations: person.create_account
        def define_creator!
          assoc = association
          owner_class.re_define_method("create_#{name}") do |*args|
            attributes, _options = parse_args(*args)
            document = Factory.build(assoc.klass, attributes)
            _assigning do
              send(:"#{assoc.name}=", document)
            end
            document.save
            save if new_record? && assoc.stores_foreign_key?
            document
          end
        end

        # Define IDs getter for collections: person.post_ids
        def define_ids_getter!
          assoc = association
          ids_method = "#{name.to_s.singularize}_ids"
          owner_class.re_define_method(ids_method) do
            send(assoc.name).pluck(:_id)
          end
        end

        # Define IDs setter for collections: person.post_ids = [...]
        def define_ids_setter!
          assoc = association
          ids_method = "#{name.to_s.singularize}_ids="
          owner_class.aliased_associations[ids_method.chop] = name.to_s
          owner_class.re_define_method(ids_method) do |ids|
            send(assoc.setter, assoc.relation_class.find(ids.reject(&:blank?)))
          end
        end
      end
    end
  end
end
