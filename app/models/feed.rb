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
    
    # basic renames
    hash['id'] = hash['facebook_id']
    hash['from'] = self.from.to_fb_hash if !self.from.nil?
    hash['to'] = self.to.to_fb_hash if !self.to.nil? and self.feed_type == 'comment'
    
    # split data back according to type
    if hash['data_type'] == 'story'
      hash['story'] = hash['data']
    elsif hash['data_type'] == 'message' or hash['data_type'] == 'comment'
      hash['message'] = hash['data']
    end

    hash['type'] = hash['feed_type']
    
    # add likes
    hash["likes"] = {
      count: hash['like_count'] || 0,
      data: []
    }
    self.likes.each do |like|
      like_hash = like.to_fb_hash
      next if like_hash.nil?
      
      hash['likes'][:data].push(like_hash)
    end
    hash['likes'][:count] = hash['likes'][:data].length

    # add comments
    hash["comments"] = {
      count: hash["comment_count"] || 0,
      data: []
    }
    self.children.each do |comment|
      comment_hash = comment.to_fb_hash
      hash['comments'][:data].push(comment_hash)
    end
    hash['comments'][:count] = hash['comments'][:data].length

    if self.feed_type == 'comment'
      hash.delete('updated_time')
    end

    # remove internal data
    hash.delete('data')
    hash.delete('feed_type')
    hash.delete('like_count')
    hash.delete('comment_count')
    hash.delete('data_type')
    hash.delete('facebook_id')
    hash.delete('created_at')
    hash.delete('updated_at')
    hash.delete('from_id')
    hash.delete('to_id')
    hash.delete('resource_id')
    hash.delete('parent_id')

    return hash
  end
end
