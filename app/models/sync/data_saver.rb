require 'active_support'

module Sync
  class DataSaver

    def initialize(prev_link, last_link)
      @@feed_prev_link_key = prev_link
      @@feed_last_link_key = last_link
    end

    # normally expect result to be the result hash
    # in case of sync errors it can either be nil or an Error class
    def save_resource(resource, result)
      @resource = resource
      @result = result

      @res_transaction = {}
      @feed_transaction = []
      @more_transaction = []

      update_resource
      save_basic_data
      save_feed

      ActiveRecord::Base.transaction do 
        @res_transaction.each { |k,res| save_resource_gracefully(res) }
        @more_transaction.each { |res| save_resource_gracefully(res) }
      end
      @res_transaction = {}
      @more_transaction = []

      ActiveRecord::Base.transaction do 
        @feed_transaction.each do |feed| 
          save_resource_gracefully(feed[:entity])
        end
      end

      @feed_transaction.each do |feed| 
        if feed[:item].has_key?('comments') and feed[:item]['comments'].has_key?('data')
          save_comments_for_feed(feed[:entity], feed[:item]["comments"]['data'])
        end
        if feed[:item].has_key?('likes') and feed[:item]['likes'].has_key?('data')
          save_likes_for_feed(feed[:entity], feed[:item]["likes"]['data'])
        end

        save_tags_for_feed(feed)
      end
      
      # resources from previous transaction (likes, comments)
      ActiveRecord::Base.transaction do 
        @res_transaction.each { |k,res| save_resource_gracefully(res) }
      end
      
      ActiveRecord::Base.transaction do 
        @more_transaction.each { |res| save_resource_gracefully(res) }
      end

    end

    def save_resource_gracefully(res)
      unless res.is_a?(ActiveRecord::Base) 
        Rails.logger.warn(Time.now.to_s + ": Invalid object provided for saving: " + res.to_s)
        return
      end

      begin
        res.save
      rescue => e
        Rails.logger.error(Time.now.to_s + ": An exception occured while trying to save #{res.inspect}: #{e.message}")
        Rails.logger.info(e.backtrace.join("\n"))
      end
    end
    
    def update_resource
      @resource.last_synced = DateTime.now

      if @result.is_a?(Hash) and @result.has_key?(:basic_data)
        @resource.facebook_id = @result[:basic_data]['id']
        @resource.name = @result[:basic_data]['name']
        @resource.username = @result[:basic_data]['username'] || @result[:basic_data]['id']
        @resource.link = @result[:basic_data]['link']
      end
      
      @more_transaction.push(@resource)
    end
    
    def save_basic_data
      return unless @result.is_a?(Hash)

      new_data = @result[:basic_data].clone
      existing_data = Basicdata.where(resource_id: @resource.id)
      feed_prev_link = nil
      feed_last_link = nil
      
      # overwrite existing values
      existing_data.each do |item|
        if new_data.has_key?(item.key)
          item.value = new_data[item.key]
          
          @more_transaction.push(item)

          new_data.delete(item.key)
        elsif item.key == @@feed_prev_link_key
          feed_prev_link = item
        elsif item.key == @@feed_last_link_key
          feed_last_link = item
        end
      end
      
      # save new values
      new_data.each do |k,v|
        if k == 'id' || k == 'name' || k == 'link' || k == 'username'
          next
        end
        basic_data = Basicdata.new
        basic_data.key = k
        basic_data.value = v
        basic_data.resource = @resource
        
        @more_transaction.push(basic_data)
      end
      
      # save special fields
      if feed_prev_link.nil?
        feed_prev_link = Basicdata.new
        feed_prev_link.key = @@feed_prev_link_key
        feed_prev_link.resource = @resource
      end
      feed_prev_link.value = @result[:feed][:previous_link] if @result[:feed][:previous_link] != ""
      @more_transaction.push(feed_prev_link)

      if feed_last_link.nil?
        feed_last_link = Basicdata.new
        feed_last_link.key = @@feed_last_link_key
        feed_last_link.resource = @resource
      end
      feed_last_link.value = @result[:feed][:resume_query]
      @more_transaction.push(feed_last_link)
    end
    
    def save_feed
      return unless @result.is_a?(Hash)
      
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
        comment.comment_count = comment_hash["comment_count"]
        
        if comment_hash.has_key?('likes') and comment_hash['likes'].has_key?('data')
          save_likes_for_feed(comment, comment_hash["likes"]['data'])
        end

        save_tags(comment, comment_hash['message_tags']) if comment_hash.has_key?('message_tags')
        
        @more_transaction.push(comment)
      end
    end
    
    def save_likes_for_feed(feed, likes)
      likes.each do |like_hash|
        like = Like.new
        like.resource = get_or_make_resource(like_hash)
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

      parse_feed_data(feed, item)

      feed.feed_type = item['type']
      feed.created_time = item['created_time']
      feed.updated_time = item['updated_time']
      feed.like_count = item['likes']['count'] if item.has_key?('likes')
      
      # get comment count
      if item.has_key?('comments')
        if item['comments'].has_key?('count')
          feed.comment_count = item['comments']['count'] 
        else
          feed.comment_count = item['comments']['data'].length
        end
      end

      if item.has_key?('to') and item['to']['data'].length > 0
        feed.to = get_or_make_resource(item['to']['data'][0])
      end
      
      return feed
    end

    def save_tags_for_feed(feed)
      save_tags(feed[:entity], feed[:item]['story_tags']) if feed[:item].has_key?('story_tags')
      save_tags(feed[:entity], feed[:item]['message_tags']) if feed[:item].has_key?('message_tags')
    end

    def save_tags(feed, tag_collection)
      tag_collection.each do |offset,tag_list|
        tag_list.each do |tag_item|
          tag = FeedTag.new
          tag.feed = feed
          tag.resource = get_or_make_resource(tag_item)
          
          @more_transaction << tag
        end
      end
    end

    def parse_feed_data(feed, item)
      if item.has_key?('message')
        feed.data = item['message'] || ""
      elsif item.has_key?('story')
        feed.data = item['story'] || ""
      else
        feed.data = ""
      end

      if item['type'] == 'link' and 
         item.has_key?('link') and 
         item.has_key?('name') and 
         item.has_key?('description')
        
        feed.data += " -- #{item['name']}: #{item['description']} #{item['link']}" 
      elsif item['type'] == 'photo' and
            item.has_key?('picture')

        feed.data += " -- #{item['picture']}"
      end
    end
    
    def get_or_make_resource(resource)
      if @res_transaction.has_key?(resource['id'])
        res = @res_transaction[ resource['id'] ] 
      else
        res = Resource.find_by_facebook_id(resource['id'])
      end
      
      if res.nil?
        res = Resource.new
        res.active = false
        res.facebook_id = resource['id']
        res.username = resource['id']
        res.name = resource['name']
        @res_transaction[ resource['id'] ] = res
      end
      
      return res
    end
  end
end