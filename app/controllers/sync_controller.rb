require 'active_support'

class SyncController < ApplicationController
  @@feed_prev_link_key = 'feed_previous_link'
  
  def index
    @username = params[:name]
    @resource = Resource.find_by_username(@username)
    
    if @resource.nil?
      redirect_to root_path, :notice => "Username not found"
    end
    
    @result = sync_resource(@resource)
    
    redirect_to resource_details_path(@resource.username)
  end

  def syncall
    resources = Resource.where({ :active => true }).all
    resource_names = []
    
    resources.each do |resource|
      sync_resource(resource)
      
      resource_names << resource.name
    end
    
    redirect_to root_path, :notice => "Synced all active resources: " + resource_names.join(", ")
  end
  
  def disable
    set_active_for(false, params[:name])
    
    redirect_to root_path, :notice => "Disabled " + params[:name]
  end
  
  def enable
    set_active_for(true, params[:name])
    
    redirect_to root_path, :notice => "Enabled " + params[:name]
  end
  
  private
  def set_active_for(active, username)
    resource = Resource.find_by_username(username)
    
    if resource.nil?
      redirect_to root_path, :notice => "Resource " + username + " not found"
      return
    end
    
    resource.active = active
    resource.save
  end
  
  def sync_resource(resource)
    gatherer = UserDataGatherer.new(resource.username, session[:facebook])
    
    prev_feed_link = Basicdata.where({ resource_id: resource, key: @@feed_prev_link_key }).first
    gatherer.prev_feed_link = prev_feed_link.value if !prev_feed_link.nil?
    
    result = gatherer.start_fetch
    
    update_resource(resource, result)
    save_basic_data(resource, result)
    save_feed(resource, result)
    
    return result
  end
  
  def update_resource(resource, result)
    resource.facebook_id = result[:basic_data]['id']
    resource.last_synced = DateTime.now
    resource.name = result[:basic_data]['name']
    resource.username = result[:basic_data]['username']
    resource.link = result[:basic_data]['link']
    if !resource.save
      flash[:alert] = 'Failed updating the resource'
    end
  end
  
  def save_basic_data(resource, result)
    new_data = result[:basic_data].clone
    existing_data = Basicdata.find_all_by_resource_id(resource.id)
    feed_prev_link = nil
    
    # overwrite existing values
    existing_data.each do |item|
      if new_data.has_key?(item.key)
        item.value = new_data[item.key].is_a?(Hash) ? ActiveSupport::JSON.encode(new_data[item.key]) : new_data[item.key]
        if !item.save
          flash[:alert] = 'Failed saving data for ' + item.key
        end
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
      basic_data.resource = resource
      
      if !basic_data.save
        flash[:alert] = 'Failed saving data for ' + basic_data.key
      end
    end
    
    # save special field
    if feed_prev_link.nil?
      feed_prev_link = Basicdata.new
      feed_prev_link.key = @@feed_prev_link_key
      feed_prev_link.resource = resource
    end
    feed_prev_link.value = result[:feed][:previous_link][ result[:feed][:previous_link].index('&')+1..-1 ] if result[:feed][:previous_link] != ""
    feed_prev_link.save
  end
  
  def save_feed(resource, result)
    feeds = result[:feed]
    
    feeds[:data].each do |item|
      feed = build_feed_out_of_item(item, resource)
      
      if item.has_key?('comments') and item['comments'].has_key?('count')
        feed.comments = item['comments']['count']
      end
      
      feed.save
      
      if item.has_key?('comments') and item['comments'].has_key?('data')
        save_comments_for_feed(feed, item["comments"]['data'])
      end
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
      comment.data = comment_hash["message"]
      comment.data_type = "comment"
      comment.feed_type = "comment"
      comment.likes = comment_hash["like_count"]
      
      comment.save
    end
  end
  
  def build_feed_out_of_item(item, resource)
    feed = Feed.find_by_facebook_id(item['id'])

    if feed.nil?
      feed = Feed.new
    end

    feed.resource = resource
    feed.facebook_id = item['id']
    feed.from = get_or_make_resource(item['from'])
    feed.data_type = item.has_key?('message') ? 'message' : 'story'
    feed.data = item.has_key?('message') ? item['message'] : item['story']
    feed.feed_type = item['type']
    feed.created_time = item['created_time']
    feed.updated_time = item['updated_time']
    feed.likes = item['likes']['count'] if item.has_key?('likes')

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
      res.save
    end
    
    return res
  end
end
