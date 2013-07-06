class Feed < ActiveRecord::Base
  attr_accessible :comment_count, :created_time, :data, :data_type, :facebook_id, :like_count, :feed_type, :updated_time
  
  belongs_to :resource
  belongs_to :from, class_name: 'Resource'
  belongs_to :to, class_name: 'Resource'
  
  has_many :likes
  
  # self-join
  belongs_to :parent, class_name: 'Feed'
  has_many :children, class_name: 'Feed', foreign_key: 'parent_id'
end
