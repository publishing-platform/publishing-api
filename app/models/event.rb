class Event < ApplicationRecord
  include SymbolizeJson

  def self.maximum_id
    Event.maximum(:id) || 0
  end
end
