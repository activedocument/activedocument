# frozen_string_literal: true

# Foreign key strategies
require 'active_document/association/referenced/v2/foreign_key/base'
require 'active_document/association/referenced/v2/foreign_key/single'
require 'active_document/association/referenced/v2/foreign_key/array'
require 'active_document/association/referenced/v2/foreign_key/none'

# Cardinality strategies
require 'active_document/association/referenced/v2/cardinality/base'
require 'active_document/association/referenced/v2/cardinality/one'
require 'active_document/association/referenced/v2/cardinality/many'

# Query builder
require 'active_document/association/referenced/v2/query/builder'

# Binding strategies
require 'active_document/association/referenced/v2/binding/base'
require 'active_document/association/referenced/v2/binding/belongs_to_one'
require 'active_document/association/referenced/v2/binding/has'
require 'active_document/association/referenced/v2/binding/many_to_many'

# Proxy classes
require 'active_document/association/referenced/v2/proxy/one'
require 'active_document/association/referenced/v2/proxy/many'

# Eager loaders
require 'active_document/association/referenced/v2/eager/base'
require 'active_document/association/referenced/v2/eager/belongs_to'
require 'active_document/association/referenced/v2/eager/has_one'
require 'active_document/association/referenced/v2/eager/has_many'
require 'active_document/association/referenced/v2/eager/belongs_to_many'

# Options and registry
require 'active_document/association/referenced/v2/options'
require 'active_document/association/referenced/v2/strategy_registry'

# Method definer
require 'active_document/association/referenced/v2/method_definer'

# Main association class
require 'active_document/association/referenced/v2/association'
