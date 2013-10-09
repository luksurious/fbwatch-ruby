class ResourceGroup < ActiveRecord::Base
  has_and_belongs_to_many :resources, -> { order('active DESC, last_synced IS NULL, last_synced DESC, created_at ASC') }
end