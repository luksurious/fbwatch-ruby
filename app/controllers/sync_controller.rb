require 'active_support'

class SyncController < ApplicationController
  @@feed_prev_link_key = 'feed_previous_link'
  
  def index
    @username = params[:name]
    @resource = Resource.find_by_username(@username)
    prev_feed_link = Basicdata.where({ resource_id: @resource, key: @@feed_prev_link_key }).first
    
    gatherer = UserDataGatherer.new(@username, session[:facebook])
    gatherer.prev_feed_link = prev_feed_link.value if !prev_feed_link.nil?
    
    @result = gatherer.start_fetch
    
    update_resource
    save_basic_data
    save_feed
    
   redirect_to controller: 'resources', action: 'details', username: @resource.username
  end

  def syncall
  end
  
  private
  def update_resource
    @resource.facebook_id = @result[:basic_data]['id']
    @resource.last_synced = DateTime.now
    @resource.name = @result[:basic_data]['name']
    @resource.link = @result[:basic_data]['link']
    if !@resource.save
      flash[:alert] = 'Failed updating the resource'
    end
  end
  
  def save_basic_data
    new_data = @result[:basic_data].clone
    existing_data = Basicdata.find_all_by_resource_id(@resource.id)
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
      basic_data.resource = @resource
      
      if !basic_data.save
        flash[:alert] = 'Failed saving data for ' + basic_data.key
      end
    end
    
    # save special field
    if feed_prev_link.nil?
      feed_prev_link = Basicdata.new
      feed_prev_link.key = @@feed_prev_link_key
      feed_prev_link.resource = @resource
    end
    feed_prev_link.value = @result[:feed][:previous_link][ @result[:feed][:previous_link].index('&')+1..-1 ] if @result[:feed][:previous_link] != ""
    feed_prev_link.save
  end
  
  def save_feed
    feeds = @result[:feed]
    
    feeds[:data].each do |item|
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
      
      if item.has_key?('to') and item['to']['data'].length > 0
        feed.to = get_or_make_resource(item['to']['data'][0])
      end
      
      feed.save
    end
    
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
