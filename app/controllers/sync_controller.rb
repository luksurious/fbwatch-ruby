
class SyncController < ApplicationController
  @@feed_prev_link_key = 'feed_previous_link'
  
  def index
    @username = params[:name]
    @resource = Resource.find_by_username(@username)
    
    if @resource.nil?
      redirect_to root_path, :notice => "Username not found"
    end
    
    pages = params[:p].to_i
    @result = sync_resource(@resource, pages)
    
    redirect_to resource_details_path(@resource.username)
  end

  def syncall
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
      Likes.where(resource_id: resource).destroy_all
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
    
    prev_feed_link = Basicdata.where({ resource_id: resource, key: @@feed_prev_link_key }).first
    gatherer.prev_feed_link = prev_feed_link.value if !prev_feed_link.nil?
    
    result = gatherer.start_fetch(pages.to_i)
    
    DataSaver.new(@@feed_prev_link_key).save_resource(resource, result)
    
    return result
  end

end
