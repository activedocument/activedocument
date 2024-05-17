# frozen_string_literal: true

if defined?(ActiveSupport)
  require 'active_support/time_with_zone' unless defined?(ActiveSupport::TimeWithZone)
  require 'active_document/criteria/queryable/extensions/time_with_zone'
end

require 'time'
require 'active_document/criteria/queryable/extensions/object'
require 'active_document/criteria/queryable/extensions/array'
require 'active_document/criteria/queryable/extensions/big_decimal'
require 'active_document/criteria/queryable/extensions/boolean'
require 'active_document/criteria/queryable/extensions/date'
require 'active_document/criteria/queryable/extensions/date_time'
require 'active_document/criteria/queryable/extensions/hash'
require 'active_document/criteria/queryable/extensions/nil_class'
require 'active_document/criteria/queryable/extensions/numeric'
require 'active_document/criteria/queryable/extensions/range'
require 'active_document/criteria/queryable/extensions/regexp'
require 'active_document/criteria/queryable/extensions/set'
require 'active_document/criteria/queryable/extensions/string'
require 'active_document/criteria/queryable/extensions/symbol'
require 'active_document/criteria/queryable/extensions/time'
