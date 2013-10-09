
class SyncController < ApplicationController
  before_action :assert_auth
  
  def resource
    @username = params[:name]
    @resource = Resource.find_by_username(@username)
    
    if @resource.nil?
      redirect_to root_path, :notice => "Username not found"
    end
    
    pages = params[:p].to_i
    page_limit = nil
    data = {}
    if params[:test] == "1"
      data = { pages: 1, page_limit: 25 }
    end

    @result = sync(resource: @resource, data: data)
    
    redirect_to resource_details_path(@resource.username)
  end

  def all
    sync(resource_group: Tasks::SyncTask::ALL)

    redirect_to resources_index_path
  end
  
  def group
    resource_group = ResourceGroup.find(params[:id])
    sync(resource_group: resource_group)
    
    redirect_to resource_group_details_path(resource_group)
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

  private
    def sync(options = {})
      entity_name = get_entity_name(options)

      sync_task = Tasks::SyncTask.new(session[:facebook], options)

      result = sync_task.run

      if result.is_a?(StandardError)
        flash[:error] << "A connection error occured: #{result.message}"
      elsif result == Tasks::SyncTask::ERROR_ALREADY_SYNCING
        flash[:warning] << "#{entity_name} is already being synced right now. Please be patient and wait for the operation to finish."
      end

      if sync_task.gatherer.is_a?(Sync::UserDataGatherer)
        flash[:error].concat(sync_task.gatherer.flash[:error])
        flash[:notice].concat(sync_task.gatherer.flash[:notice])
        
        data_time = sync_task.task.data[Tasks::SyncTask::DATA_TIME]
        save_time = sync_task.task.data[Tasks::SyncTask::SAVE_TIME]
        total_time = data_time + save_time
        flash[:notice] << "Syncing of #{entity_name} took #{data_time}s + #{save_time}s = #{total_time}s, total calls: #{sync_task.gatherer.no_of_queries}"
      end


      return result
    end

    def get_entity_name(options)
      if options[:resource].is_a?(Resource)
        return options[:resource].username
      elsif options[:resource_group].is_a?(ResourceGroup)
        return options[:resource_group].group_name
      elsif options[:resource_group] == Tasks::SyncTask::ALL
        return 'all'
      end
    end
end
