class Resource < ActiveRecord::Base
  attr_accessible :active, :facebook_id, :last_synced, :name, :username, :link
  
  validates :username, :presence => true
  validates :facebook_id, :uniqueness => true
  
  has_many :basicdata
  has_many :feed
  
  def to_fb_hash
    { 
      id: self.facebook_id, 
      name: self.name, 
      username: self.username
    }
  end
end
