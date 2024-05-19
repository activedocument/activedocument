# frozen_string_literal: true

class Filesystem
  include ActiveDocument::Document
  include ActiveDocument::Attributes::Dynamic
  embedded_in :server
end
