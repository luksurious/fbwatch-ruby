
class SyncController < ApplicationController
  
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
    page_limit = nil
    if params[:test] == "1"
      pages = 1
      page_limit = 25
    end

    @result = sync_resource(@resource, pages, page_limit)
    
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
      sync_resource(resource, -1, nil)
      
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
    
    resource.last_synced = nil
    resource.active = false
    ActiveRecord::Base.transaction do 
      Feed.where(resource_id: resource).destroy_all
      Basicdata.where(resource_id: resource).destroy_all
      Like.where(resource_id: resource).destroy_all
      resource.save
    end

    redirect_to resource_details_path(params[:name])
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
  
  def sync_resource(resource, pages, page_limit)
    return false if resource_currently_syncing?(resource)

    gatherer = UserDataGatherer.new(resource.username, session[:facebook])

    # set query to resume; might be best to push to resource table
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

    gatherer.page_limit = page_limit if !page_limit.nil?
    result = nil
    data_time = SyncHelper.time do
      result = gatherer.start_fetch(pages.to_i)
    end

    flash[:error].concat(gatherer.flash[:error])
    flash[:notice].concat(gatherer.flash[:notice])

    save_time = SyncHelper.time do
      DataSaver.new(@@feed_prev_link_key, @@feed_last_link_key).save_resource(resource, result)
    end
    total_time = data_time + save_time
    flash[:notice] << "Syncing of #{resource.username} took #{data_time}s + #{save_time}s = #{total_time}s, total calls: #{gatherer.no_of_queries}"

    return result
  end

  def resource_currently_syncing?(resource)
    if resource.last_synced.is_a?(Time) and resource.last_synced > DateTime.now
      flash[:warning] << "Resource #{resource.username} is already being synced right now. Please be patient and wait for the operation to finish."
      return true
    end
  
    resource.last_synced = Time.now.tomorrow
    resource.save!
    return false
  end
end
