class ResourceGroup < ActiveRecord::Base
  has_and_belongs_to_many :resources, -> { order(active: :desc, last_synced: :desc) }
end