# frozen_string_literal: true

# Shared modules
require 'active_document/association/referenced/counter_cache'
require 'active_document/association/referenced/syncable'

# Options (no dependencies)
require 'active_document/association/referenced/options'

# Foreign key strategies (no dependencies)
require 'active_document/association/referenced/foreign_key/base'
require 'active_document/association/referenced/foreign_key/single'
require 'active_document/association/referenced/foreign_key/array'
require 'active_document/association/referenced/foreign_key/none'

# Cardinality strategies (no dependencies)
require 'active_document/association/referenced/cardinality/base'
require 'active_document/association/referenced/cardinality/one'
require 'active_document/association/referenced/cardinality/many'

# Binding strategies (depends on base)
require 'active_document/association/referenced/binding/base'
require 'active_document/association/referenced/binding/belongs_to_one'
require 'active_document/association/referenced/binding/has'
require 'active_document/association/referenced/binding/many_to_many'

# HasMany::Enumerable (used by Proxy::Many)
require 'active_document/association/referenced/has_many/enumerable'

# Proxy classes (no dependencies within module)
require 'active_document/association/referenced/proxy/one'
require 'active_document/association/referenced/proxy/many'

# Eager loaders (depends on base)
require 'active_document/association/referenced/eager/base'
require 'active_document/association/referenced/eager/belongs_to'
require 'active_document/association/referenced/eager/has_one'
require 'active_document/association/referenced/eager/has_many'
require 'active_document/association/referenced/eager/belongs_to_many'

# Query builder
require 'active_document/association/referenced/query/builder'

# Strategy registry (depends on all strategy classes)
require 'active_document/association/referenced/strategy_registry'

# Method definer (no dependencies within module)
require 'active_document/association/referenced/method_definer'

# Main association class (depends on everything)
require 'active_document/association/referenced/association'
