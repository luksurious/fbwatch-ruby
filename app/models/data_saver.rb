require 'active_support'

class DataSaver

  def initialize(prev_link)
    @@feed_prev_link_key = prev_link
  end

  def save_resource(resource, result)
    @resource = resource
    @result = result

    @res_transaction = []
    @feed_transaction = []
    @more_transaction = []

    update_resource
    save_basic_data
    save_feed

    ActiveRecord::Base.transaction do 
      @res_transaction.each { |res| res.save }
    end
    @res_transaction = []

    ActiveRecord::Base.transaction do 
      @feed_transaction.each do |feed| 
        feed[:entity].save
      end
    end

    @feed_transaction.each do |feed| 
      if feed[:item].has_key?('comments') and feed[:item]['comments'].has_key?('data')
        save_comments_for_feed(feed[:entity], feed[:item]["comments"]['data'])
      end
      if feed[:item].has_key?('likes') and feed[:item]['likes'].has_key?('data')
        save_likes_for_feed(feed[:entity], feed[:item]["likes"]['data'])
      end
    end
    
    ActiveRecord::Base.transaction do 
      @res_transaction.each { |res| res.save }
      @more_transaction.each { |res| res.save }
    end

  end
  
  def update_resource
    @resource.facebook_id = @result[:basic_data]['id']
    @resource.last_synced = DateTime.now
    @resource.name = @result[:basic_data]['name']
    @resource.username = @result[:basic_data]['username']
    @resource.link = @result[:basic_data]['link']
    
    @res_transaction.push(@resource)
  end
  
  def save_basic_data
    new_data = @result[:basic_data].clone
    existing_data = Basicdata.find_all_by_resource_id(@resource.id)
    feed_prev_link = nil
    
    # overwrite existing values
    existing_data.each do |item|
      if new_data.has_key?(item.key)
        item.value = new_data[item.key].is_a?(Hash) ? ActiveSupport::JSON.encode(new_data[item.key]) : new_data[item.key]
        
        @res_transaction.push(item)

        new_data.delete(item.key)
      elsif item.key == @@feed_prev_link_key
        feed_prev_link = item
      end
    end
    
    # save new values
    new_data.each do |k,v|
      if k == 'id' || k == 'name' || k == 'link' || k == 'username'
        next
      end
      basic_data = Basicdata.new
      basic_data.key = k
      basic_data.value = v.is_a?(Hash) ? ActiveSupport::JSON.encode(v) : v
      basic_data.resource = @resource
      
      @res_transaction.push(basic_data)
    end
    
    # save special field
    if feed_prev_link.nil?
      feed_prev_link = Basicdata.new
      feed_prev_link.key = @@feed_prev_link_key
      feed_prev_link.resource = @resource
    end
    feed_prev_link.value = @result[:feed][:previous_link][ @result[:feed][:previous_link].index('&')+1..-1 ] if @result[:feed][:previous_link] != ""
    @res_transaction.push(feed_prev_link)
  end
  
  def save_feed
    feeds = @result[:feed]
    
    feeds[:data].each do |item|
      feed = build_feed_out_of_item(item)
      
      if item.has_key?('comments') and item['comments'].has_key?('count')
        feed.comment_count = item['comments']['count']
      end
      
      @feed_transaction.push({entity: feed, item: item})
    end
    
  end
  
  def save_comments_for_feed(feed, comments)
    comments.each do |comment_hash|
      comment = Feed.new
      comment.parent_id = feed.id
      comment.resource = feed.resource
      comment.created_time = comment_hash["created_time"]
      comment.updated_time = comment_hash["created_time"]
      comment.facebook_id = comment_hash["id"]
      comment.from = get_or_make_resource(comment_hash["from"])
      comment.to = @resource
      comment.data = comment_hash["message"]
      comment.data_type = "comment"
      comment.feed_type = "comment"
      comment.like_count = comment_hash["like_count"]
      
      @more_transaction.push(comment)
    end
  end
  
  def save_likes_for_feed(feed, likes)
    likes.each do |like_hash|
      like = Likes.new
      like.resource = feed.resource
      like.feed = feed
      
      @more_transaction.push(like)
    end
  end
  
  def build_feed_out_of_item(item)
    feed = Feed.find_by_facebook_id(item['id'])

    if feed.nil?
      feed = Feed.new
    end

    feed.resource = @resource
    feed.facebook_id = item['id']
    feed.from = get_or_make_resource(item['from'])
    feed.data_type = item.has_key?('message') ? 'message' : 'story'
    feed.data = item.has_key?('message') ? item['message'] : item['story']
    feed.feed_type = item['type']
    feed.created_time = item['created_time']
    feed.updated_time = item['updated_time']
    feed.like_count = item['likes']['count'] if item.has_key?('likes')

    if item.has_key?('to') and item['to']['data'].length > 0
      feed.to = get_or_make_resource(item['to']['data'][0])
    end
    
    return feed
  end
  
  def get_or_make_resource(resource)
    res = Resource.find_by_facebook_id resource['id']
    
    if res.nil?
      res = Resource.new
      res.active = false
      res.facebook_id = resource['id']
      res.username = resource['id']
      res.name = resource['name']
      @res_transaction.push(res)
    end
    
    return res
  end
end