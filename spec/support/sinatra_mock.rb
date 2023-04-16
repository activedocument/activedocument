# frozen_string_literal: true

module Sinatra
  module Base
    extend self

    def environment
      :staging
    end
  end
end
