
class SyncController < ApplicationController
  before_action :assert_auth

  @@feed_prev_link_key = 'feed_previous_link'
  @@feed_last_link_key = 'feed_last_link'
  
  def resource
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

    @result = sync_resource(@resource, pages: pages, page_limit: page_limit)
    
    redirect_to resource_details_path(@username)
  end

  def all
    resources = Resource.where({ :active => true }).all
    sync_resource_collection(resources)
  end
  
  def clear
    resource = Resource.find_by_username(params[:name])
    
    resource.last_synced = nil
    # resource.active = false
    ActiveRecord::Base.transaction do 
      Feed.where(resource_id: resource).destroy_all
      Basicdata.where(resource_id: resource).destroy_all
      Like.where(resource_id: resource).destroy_all
      resource.save
    end

    redirect_to resource_details_path(params[:name])
  end
  
  def group
    resource_group = ResourceGroup.find(params[:id])
    sync_resource_collection(resource_group.resources)
  end

  private
    def sync_resource_collection(collection, redirect = root_path)
      resource_names = []
      
      collection.each do |resource|
        next if resource.active == false

        sync_resource(resource)
        
        resource_names << resource.name
      end
      
      redirect_to redirect, :notice => "Synced resources: " + resource_names.join(", ")
    end

    def sync_resource(resource, options = {})
      return false if resource_currently_syncing?(resource)

      gatherer = setup_gatherer(resource)

      result = nil
      data_time = SyncHelper.time do
        result = use_gatherer_to_sync(gatherer, options)
      end

      save_time = SyncHelper.time do
        DataSaver.new(@@feed_prev_link_key, @@feed_last_link_key).save_resource(resource, result)
      end

      total_time = data_time + save_time
      flash[:notice] << "Syncing of #{resource.username} took #{data_time}s + #{save_time}s = #{total_time}s, total calls: #{gatherer.no_of_queries}"

      return result
    end

    def use_gatherer_to_sync(gatherer, options)
      gatherer.page_limit = options[:page_limit] unless options[:page_limit].blank?

      result = gatherer.start_fetch((options[:pages] || -1).to_i)
      flash[:error].concat(gatherer.flash[:error])
      flash[:notice].concat(gatherer.flash[:notice])

      return result
    end

    def setup_gatherer(resource)
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

      return gatherer
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
