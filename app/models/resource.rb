class Resource < ActiveRecord::Base
#  attr_accessible :active, :facebook_id, :last_synced, :name, :username, :link
  
  validates :username, :presence => true
  validates :facebook_id, :uniqueness => true
  
  has_many :basicdata
  # wrong naming scheme for feed (singular)
  has_many :feed
  
  has_many :metrics

  has_and_belongs_to_many :resource_groups
  has_and_belongs_to_many :group_metrics
  
  def to_fb_hash
    { 
      id: self.facebook_id, 
      name: self.name
    }
  end

  def activate
    self.active = true
  end

  def deactivate
    self.active = false
  end

  def sync_complete?
    resume_query = Basicdata.where({resource_id: self.id, key: Tasks::SyncTask::FEED_KEY_LAST}).first
    last_query = Basicdata.where({resource_id: self.id, key: Tasks::SyncTask::FEED_KEY_PREV}).first

    !resume_query.nil? and resume_query.value.blank? and 
      !last_query.nil? and !last_query.value.blank?
  end

  def dummy?
    self.feed.count == 0
  end
end
