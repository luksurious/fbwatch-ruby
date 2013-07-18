
class SyncController < ApplicationController
  include SessionsHelper
  
  @@feed_prev_link_key = 'feed_previous_link'
  @@feed_last_link_key = 'feed_last_link'
  
  def index
    if !signed_in?
      redirect_to login_path
      return
    end

    @username = params[:name]
    @resource = Resource.find_by_username(@username)
    
    if @resource.nil?
      redirect_to root_path, :notice => "Username not found"
    end
    
    pages = params[:p].to_i
    @result = sync_resource(@resource, pages)
    
    redirect_to resource_details_path(@username)
  end

  def syncall
    if !signed_in?
      redirect_to login_path
      return
    end

    resources = Resource.where({ :active => true }).all
    resource_names = []
    
    resources.each do |resource|
      sync_resource(resource, -1)
      
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
  
  def clear
    resource = Resource.find_by_username(params[:name])
    
    ActiveRecord::Base.transaction do 
      Feed.where(resource_id: resource).destroy_all
      Basicdata.where(resource_id: resource).destroy_all
      Like.where(resource_id: resource).destroy_all
    end
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
  
  def sync_resource(resource, pages)
    gatherer = UserDataGatherer.new(resource.username, session[:facebook])
    
    # set query to resume
    resource_config = Basicdata.where({ resource_id: resource, key: [@@feed_prev_link_key, @@feed_last_link_key] })
    link_set = false
    resource_config.each do |link_hash|
      if link_hash.key == @@feed_last_link_key and link_hash.value != ""
        gatherer.prev_feed_link = link_hash.value
        link_set = true
      elsif link_hash.key == @@feed_prev_link_key and link_set == false
        gatherer.prev_feed_link = link_hash.value
      end
    end
    
    result = gatherer.start_fetch(pages.to_i)
    
    DataSaver.new(@@feed_prev_link_key, @@feed_last_link_key).save_resource(resource, result)
    
    return result
  end

end
