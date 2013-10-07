class Feed < ActiveRecord::Base
# attr_accessible :comment_count, :created_time, :data, :data_type, :facebook_id, :like_count, :feed_type, :updated_time
  
  belongs_to :resource
  belongs_to :from, class_name: 'Resource'
  belongs_to :to, class_name: 'Resource'
  
  has_many :likes
  has_many :feed_tags
  
  # self-join
  belongs_to :parent, class_name: 'Feed'
  has_many :children, class_name: 'Feed', foreign_key: 'parent_id'
  
  def to_fb_hash
    hash = as_json
    
    hash["likes"] = {
      count: hash["like_count"],
      data: []
    }
    self.likes.each do |like|
      like_hash = like.to_fb_hash
      next if like_hash.nil?
      
      hash['likes'][:data].push(like_hash)
    end
    hash.delete('like_count')

    hash["comments"] = {
      count: hash["comment_count"],
      data: []
    }
    self.children.each do |comment|
      comment_hash = comment.to_fb_hash
      comment_hash.delete('parent_id')
      hash['comments'][:data].push(comment_hash)
    end
    hash.delete('comment_count')
    
    hash['from'] = self.from.to_fb_hash if !self.from.nil?
    hash['to'] = self.to.to_fb_hash if !self.to.nil?
    hash.delete('from_id')
    hash.delete('to_id')
    hash.delete('resource_id')
    hash['id'] = hash['facebook_id']
    hash.delete('facebook_id')
    hash.delete('created_at')
    hash.delete('updated_at')
    
    if hash['data_type'] == 'story'
      hash['story'] = hash['data']
      hash.delete('data')
    elsif hash['data_type'] == 'message' or hash['data_type'] == 'comment'
      hash['message'] = hash['data']
      hash.delete('data')
    end
    
    return hash
  end
end
