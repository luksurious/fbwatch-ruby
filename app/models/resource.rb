class Resource < ActiveRecord::Base
  attr_accessible :active, :facebook_id, :last_synced, :name
  
  validates :name, :presence => true
  
  has_one :basicdata
end
