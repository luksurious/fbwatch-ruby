class Resource < ActiveRecord::Base
  attr_accessible :active, :facebook_id, :last_synced, :name, :username, :link
  
  validates :username, :presence => true
  
  has_one :basicdata
end
