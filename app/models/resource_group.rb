class ResourceGroup < ActiveRecord::Base
  has_and_belongs_to_many :resources, order: 'active DESC, last_synced DESC'
end