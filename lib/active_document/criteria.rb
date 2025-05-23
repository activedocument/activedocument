# frozen_string_literal: true

require 'active_document/criteria/findable'
require 'active_document/criteria/includable'
require 'active_document/criteria/inspectable'
require 'active_document/criteria/marshalable'
require 'active_document/criteria/modifiable'
require 'active_document/criteria/queryable'
require 'active_document/criteria/scopable'
require 'active_document/criteria/options'
require 'active_document/criteria/translator'

module ActiveDocument

  # The +Criteria+ class is the core object needed in ActiveDocument to retrieve
  # objects from the database. It is a DSL that essentially sets up the
  # selector and options arguments that get passed on to a Mongo::Collection
  # in the Ruby driver. Each method on the +Criteria+ returns self to they
  # can be chained in order to create a readable criterion to be executed
  # against the database.
  class Criteria
    include Enumerable

    # @api private
    alias_method :_enumerable_find, :find

    include Contextual
    include Queryable
    include Findable

    # @api private
    alias_method :_findable_find, :find

    include Inspectable
    include Includable
    include Marshalable
    include Modifiable
    include Scopable
    include Clients::Options
    include Clients::Sessions
    include Options

    class << self
      # Convert the given hash to a criteria. Will iterate over each keys in the
      # hash which must correspond to method on a criteria object. The hash
      # must also include a "klass" key.
      #
      # @example Convert the hash to a criteria.
      #   Criteria.from_hash({ klass: Band, where: { name: "Depeche Mode" })
      #
      # @param [ Hash ] hash The hash to convert.
      #
      # @return [ Criteria ] The criteria.
      def from_hash(hash)
        criteria = Criteria.new(hash.delete(:klass) || hash.delete('klass'))
        hash.each_pair do |method, args|
          criteria = criteria.__send__(method, args)
        end
        criteria
      end
    end

    # Static array used to check with method missing - we only need to ever
    # instantiate once.
    CHECK = [].freeze

    attr_accessor :embedded, :klass, :parent_document, :association

    # Returns true if the supplied +Enumerable+ or +Criteria+ is equal to the results
    # of this +Criteria+ or the criteria itself.
    #
    # @note This will force a database load when called if an enumerable is passed.
    #
    # @param [ Object ] other The other +Enumerable+ or +Criteria+ to compare to.
    #
    # @return [ true | false ] If the objects are equal.
    def ==(other)
      return super if other.respond_to?(:selector)

      entries == other
    end

    # Finds one or many documents given the provided _id values, or filters
    # the documents in the current scope in the application process space
    # after loading them if needed.
    #
    # If this method is not given a block, it delegates to +Findable#find+
    # and finds one or many documents for the provided _id values.
    #
    # If this method is given a block, it delegates to +Enumerable#find+ and
    # returns the first document of those found by the current Crieria object
    # for which the block returns a truthy value.
    #
    # Note that the "default proc" argument of Enumerable is not specially
    # treated by ActiveDocument - the decision between delegating to +Findable+ vs
    # +Enumerable+ is made solely based on whether +find+ is passed a block.
    #
    # @note Each argument can be an individual id, an array of ids or
    #   a nested array. Each array will be flattened.
    #
    # @example Finds a document by its _id, invokes Findable#find.
    #   critera.find("1234")
    #
    # @example Finds the first matching document using a block, invokes Enumerable#find.
    #   criteria.find { |item| item.name == "Depeche Mode" }
    #
    # @example Finds the first matching document using a block using the default Proc, invokes Enumerable#find.
    #   criteria.find(-> { "Default Band" }) { |item| item.name == "Milwaukee Mode" }
    #
    # @example Tries to find a document whose _id is the stringification of the provided Proc, typically failing.
    #   enumerator = criteria.find(-> { "Default Band" })
    #
    # @param [ [ Object | Array<Object> ]... ] *args The id(s).
    # @param &block Optional block to pass.
    # @yield [ Object ] Yields each enumerable element to the block.
    #
    # @return [ ActiveDocument::Document | Array<ActiveDocument::Document> | nil ] A document or matching documents.
    #
    # @raise Errors::DocumentNotFound If the parameters were _id values and
    #   not all documents are found and the +raise_not_found_error+
    #   ActiveDocument configuration option is truthy.
    #
    # @see https://ruby-doc.org/core/Enumerable.html#method-i-find
    def find(*args, &block)
      if block
        _enumerable_find(*args, &block)
      else
        _findable_find(*args)
      end
    end

    # Needed to properly get a criteria back as json
    #
    # @example Get the criteria as json.
    #   Person.where(:title => "Sir").as_json
    #
    # @param [ Hash ] options Options to pass through to the serializer.
    #
    # @return [ String ] The JSON string.
    def as_json(options = nil)
      entries.as_json(options)
    end

    # Get the documents from the embedded criteria.
    #
    # @example Get the documents.
    #   criteria.documents
    #
    # @return [ Array<ActiveDocument::Document> ] The documents.
    def documents
      @documents ||= []
    end

    # Set the embedded documents on the criteria.
    #
    # @example Set the documents.
    #
    # @param [ Array<ActiveDocument::Document> ] docs The embedded documents.
    #
    # @return [ Array<ActiveDocument::Document> ] The embedded documents.
    attr_writer :documents

    # Is the criteria for embedded documents?
    #
    # @example Is the criteria for embedded documents?
    #   criteria.embedded?
    #
    # @return [ true | false ] If the criteria is embedded.
    def embedded?
      !!@embedded
    end

    # Extract a single id from the provided criteria. Could be in an $and
    # query or a straight _id query.
    #
    # @example Extract the id.
    #   criteria.extract_id
    #
    # @return [ Object ] The id.
    def extract_id
      selector['_id'] || selector[:_id] || selector['id'] || selector[:id]
    end

    # Adds a criterion to the +Criteria+ that specifies additional options
    # to be passed to the Ruby driver, in the exact format for the driver.
    #
    # @example Add extra params to the criteria.
    # criteria.extras(:limit => 20, :skip => 40)
    #
    # @param [ Hash ] extras The extra driver options.
    #
    # @return [ ActiveDocument::Criteria ] The cloned criteria.
    def extras(extras)
      crit = clone
      crit.options.merge!(extras)
      crit
    end

    # Get the list of included fields.
    #
    # @example Get the field list.
    #   criteria.field_list
    #
    # @return [ Array<String> ] The fields.
    def field_list
      if options[:fields]
        options[:fields].keys.reject { |key| key == klass.discriminator_key }
      else
        []
      end
    end

    # When freezing a criteria we need to initialize the context first
    # otherwise the setting of the context on attempted iteration will raise a
    # runtime error.
    #
    # @example Freeze the criteria.
    #   criteria.freeze
    #
    # @return [ ActiveDocument::Criteria ] The frozen criteria.
    def freeze
      context and inclusions and super
    end

    # Initialize the new criteria.
    #
    # @example Init the new criteria.
    #   Criteria.new(Band)
    #
    # @param [ Class ] klass The model class.
    def initialize(klass)
      @klass = klass
      @embedded = nil
      @none = nil
      klass ? super(klass.aliased_fields, klass.fields, klass.relations, klass.aliased_associations) : super({}, {}, {}, {})
    end

    # Merges another object with this +Criteria+ and returns a new criteria.
    # The other object may be a +Criteria+ or a +Hash+. This is used to
    # combine multiple scopes together, where a chained scope situation
    # may be desired.
    #
    # @example Merge the criteria with another criteria.
    #   criteria.merge(other_criteria)
    #
    # @example Merge the criteria with a hash. The hash must contain a klass
    #   key and the key/value pairs correspond to method names/args.
    #
    #   criteria.merge({
    #     klass: Band,
    #     where: { name: "Depeche Mode" },
    #     order_by: { name: 1 }
    #   })
    #
    # @param [ ActiveDocument::Criteria ] other The other criterion to merge with.
    #
    # @return [ ActiveDocument::Criteria ] A cloned self.
    def merge(other)
      crit = clone
      crit.merge!(other)
      crit
    end

    # Merge the other criteria into this one.
    #
    # @example Merge another criteria into this criteria.
    #   criteria.merge(Person.where(name: "bob"))
    #
    # @param [ ActiveDocument::Criteria | Hash ] other The criteria to merge in.
    #
    # @return [ ActiveDocument::Criteria ] The merged criteria.
    def merge!(other)
      other = self.class.from_hash(other) if other.is_a?(Hash)
      selector.merge!(other.selector)
      options.merge!(other.options)
      self.documents = other.documents.dup unless other.documents.empty?
      self.scoping_options = other.scoping_options
      self.inclusions = (inclusions + other.inclusions).uniq
      self
    end

    # Returns a criteria that will always contain zero results and never hits
    # the database.
    #
    # @example Return a none criteria.
    #   criteria.none
    #
    # @return [ ActiveDocument::Criteria ] The none criteria.
    def none
      @none = true and self
    end

    # Is the criteria an empty but chainable criteria?
    #
    # @example Is the criteria a none criteria?
    #   criteria.empty_and_chainable?
    #
    # @return [ true | false ] If the criteria is a none.
    def empty_and_chainable?
      !!@none
    end

    # Overriden to include _type in the fields.
    #
    # @example Limit the fields returned from the database.
    #   Band.only(:name)
    #
    # @param [ [ Symbol | Array<Symbol> ]... ] *args The field name(s).
    #
    # @return [ ActiveDocument::Criteria ] The cloned criteria.
    def only(*args)
      args = args.flatten
      return clone if args.empty?

      args.unshift(:_id) unless args.intersect?(Fields::IDS)
      args.push(klass.discriminator_key.to_sym) if klass.hereditary?

      super(*args)
    end

    # Set the read preference for the criteria.
    #
    # @example Set the read preference.
    #   criteria.read(mode: :primary_preferred)
    #
    # @param [ Hash ] value The mode preference.
    #
    # @return [ ActiveDocument::Criteria ] The cloned criteria.
    def read(value = nil)
      clone.tap do |criteria|
        criteria.options.merge!(read: value)
      end
    end

    # Overriden to exclude _id from the fields.
    #
    # @example Exclude fields returned from the database.
    #   Band.without(:name)
    #
    # @param [ Symbol... ] *args The field name(s).
    #
    # @return [ ActiveDocument::Criteria ] The cloned criteria.
    def without(*args)
      args -= id_fields
      super(*args)
    end

    # Returns true if criteria responds to the given method.
    #
    # @example Does the criteria respond to the method?
    #   crtiteria.respond_to?(:each)
    #
    # @param [ Symbol ] name The name of the class method on the +Document+.
    # @param [ true | false ] include_private Whether to include privates.
    #
    # @return [ true | false ] If the criteria responds to the method.
    def respond_to?(name, include_private = false)
      super || klass.respond_to?(name) || CHECK.respond_to?(name, include_private)
    end

    alias_method :to_ary, :to_a

    # Convert the criteria to a proc.
    #
    # @example Convert the criteria to a proc.
    #   criteria.to_proc
    #
    # @return [ Proc ] The wrapped criteria.
    def to_proc
      -> { self }
    end

    # Adds a criterion to the +Criteria+ that specifies a type or an Array of
    # types that must be matched.
    #
    # @example Match only specific models.
    #   criteria.type('Browser')
    #   criteria.type(['Firefox', 'Browser'])
    #
    # @param [ Array<String> ] types The types to match against.
    #
    # @return [ ActiveDocument::Criteria ] The cloned criteria.
    def type(types)
      any_in(discriminator_key.to_sym => Array(types))
    end

    # This is the general entry point for most MongoDB queries. This either
    # creates a standard field: value selection, and expanded selection with
    # the use of hash methods, or a $where selection if a string is provided.
    #
    # @example Add a standard selection.
    #   criteria.where(name: "syd")
    #
    # @example Add a javascript selection.
    #   criteria.where("this.name == 'syd'")
    #
    # @param [ [ Hash | String ]... ] *args The standard selection
    #   or javascript string.
    #
    # @raise [ UnsupportedJavascript ] If provided a string and the criteria
    #   is embedded.
    #
    # @return [ ActiveDocument::Criteria ] The cloned selectable.
    def where(*args)
      # Historically this method required exactly one argument.
      # As of https://jira.mongodb.org/browse/MONGOID-4804 it also accepts
      # zero arguments.
      # The underlying where implemetation that super invokes supports
      # any number of arguments, but we don't presently allow mutiple
      # arguments through this method. This API can be reconsidered in the
      # future.
      if args.length > 1
        raise ArgumentError.new("Criteria#where requires zero or one arguments (given #{args.length})")
      end

      if args.length == 1
        expression = args.first
        if expression.is_a?(::String) && embedded?
          raise Errors::UnsupportedJavascript.new(klass, expression)
        end
      end

      super
    end

    # Get a version of this criteria without the options.
    #
    # @example Get the criteria without options.
    #   criteria.without_options
    #
    # @return [ ActiveDocument::Criteria ] The cloned criteria.
    def without_options
      crit = clone
      crit.options.clear
      crit
    end

    # Find documents by the provided javascript and scope. Uses a $where but is
    # different from +Criteria#where+ in that it will pass a code object to the
    # query instead of a pure string. Safe against Javascript injection
    # attacks.
    #
    # @example Find by javascript.
    #   Band.for_js("this.name = param", param: "Tool")
    #
    # @param [ String ] javascript The javascript to execute in the $where.
    # @param [ Hash ] scope The scope for the code.
    #
    # @return [ ActiveDocument::Criteria ] The criteria.
    #
    # @deprecated
    def for_js(javascript, scope = {})
      code = if scope.empty?
               # CodeWithScope is not supported for $where as of MongoDB 4.4
               BSON::Code.new(javascript)
             else
               BSON::CodeWithScope.new(javascript, scope)
             end
      js_query(code)
    end
    ActiveDocument.deprecate(self, :for_js)

    private

    # Are documents in the query missing, and are we configured to raise an
    # error?
    #
    # @api private
    #
    # @example Check for missing documents.
    #   criteria.check_for_missing_documents!([], [ 1 ])
    #
    # @param [ Array<ActiveDocument::Document> ] result The result.
    # @param [ Array<Object> ] ids The ids.
    #
    # @raise [ Errors::DocumentNotFound ] If none are found and raising an
    #   error.
    def check_for_missing_documents!(result, ids)
      return unless ActiveDocument.raise_not_found_error && (result.size < ids.size)

      raise Errors::DocumentNotFound.new(klass, ids, ids - result.map(&:_id))
    end

    # Clone or dup the current +Criteria+. This will return a new criteria with
    # the selector, options, klass, embedded options, etc intact.
    #
    # @api private
    #
    # @example Clone a criteria.
    #   criteria.clone
    #
    # @example Dup a criteria.
    #   criteria.dup
    #
    # @param [ ActiveDocument::Criteria ] other The criteria getting cloned.
    #
    # @return [ nil ] nil.
    def initialize_copy(other)
      @inclusions = other.inclusions.dup
      @scoping_options = other.scoping_options
      @documents = other.documents.dup
      @context = nil
      super
    end

    # Used for chaining +Criteria+ scopes together in the for of class methods
    # on the +Document+ the criteria is for.
    #
    # @example Handle method missing.
    #   criteria.method_missing(:name)
    #
    # @param [ Symbol ] name The method name.
    # @param [ Object... ] *args The arguments.
    #
    # @return [ Object ] The result of the method call.
    def method_missing(name, ...)
      if klass.respond_to?(name)
        klass.public_send(:with_scope, self) do
          klass.public_send(name, ...)
        end
      elsif CHECK.respond_to?(name)
        entries.public_send(name, ...)
      else
        super
      end
    end

    # Check if the method can be handled by method_missing.
    #
    # @param [ Symbol | String ] name The name of the method.
    # @param [ true | false ] _include_private Whether to include private methods.
    #
    # @return [ true | false ] True if method can be handled, false otherwise.
    def respond_to_missing?(name, _include_private = false)
      klass.respond_to?(name) || CHECK.respond_to?(name)
    end

    # For models where inheritance is at play we need to add the type
    # selection.
    #
    # @example Add the type selection.
    #   criteria.merge_type_selection
    #
    # @return [ true | false ] If type selection was added.
    def merge_type_selection
      selector.merge!(type_selection) if type_selectable?
    end

    # Is the criteria type selectable?
    #
    # @api private
    #
    # @example If the criteria type selectable?
    #   criteria.type_selectable?
    #
    # @return [ true | false ] If type selection should be added.
    def type_selectable?
      klass.hereditary? &&
        selector.keys.exclude?(discriminator_key) &&
        selector.keys.exclude?(discriminator_key.to_sym)
    end

    # Get the selector for type selection.
    #
    # @api private
    #
    # @example Get a type selection hash.
    #   criteria.type_selection
    #
    # @return [ Hash ] The type selection.
    def type_selection
      klasses = klass._types
      if klasses.size > 1
        { klass.discriminator_key.to_sym => { '$in' => klass._types } }
      else
        { klass.discriminator_key.to_sym => klass._types[0] }
      end
    end

    # Get a new selector with type selection in it.
    #
    # @api private
    #
    # @example Get a selector with type selection.
    #   criteria.selector_with_type_selection
    #
    # @return [ Hash ] The selector.
    def selector_with_type_selection
      type_selectable? ? selector.merge(type_selection) : selector
    end
  end
end
