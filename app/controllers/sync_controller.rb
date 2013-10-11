
class SyncController < ApplicationController
  before_action :assert_auth
  
  def resource
    @username = params[:name]
    @resource = Resource.find_by_username(@username)
    
    if @resource.nil?
      flash[:info] << 'Username not found'
      redirect_to root_path
    end
    
    pages = params[:p].to_i
    page_limit = nil
    data = {}
    if params[:test] == "1"
      data = { pages: 1, page_limit: 25 }
    end

    sync(resource: @resource, data: data)
    
    flash[:notice] << "This resource is now being synced. Watch the progress on the task page."
    redirect_to resource_details_path(@resource.username)
  end

  def all
    sync(resource_group: Tasks::SyncTask::ALL)

    flash[:notice] << "All resources are now being synced. Watch the progress on the task page."
    redirect_to :back
  end
  
  def group
    resource_group = ResourceGroup.find(params[:id])
    sync(resource_group: resource_group)
    
    flash[:notice] << "This group is now being synced. Watch the progress on the task page."
    redirect_to resource_group_details_path(resource_group)
  end
  
  def clear
    resource = Resource.find_by_username(params[:name])
    
    resource.clear

    flash[:notice] << "Successfully cleared resource #{resource.name}"
    redirect_to resource_details_path(params[:name])
  end
  
  def clear_group
    resource_group = ResourceGroup.find(params[:id])
    
    resource_group.resources.each do |resource|
      resource.clear
    end

    flash[:notice] << "Successfully cleared group #{resource_group.group_name}"
    redirect_to resource_group_details_path(resource_group)
  end

  private

    def sync(options = {})
      entity_name = get_entity_name(options)

      sync_task = Tasks::SyncTask.new(session[:facebook], options)

      SyncTaskWorker.perform_async('token' => session[:facebook].access_token, 'task' => sync_task.task.id)
      
      # result = sync_task.run

      # if result.is_a?(StandardError)
      #   flash[:alert] << "A connection error occured: #{result.message}"
      # elsif result == Tasks::SyncTask::ERROR_ALREADY_SYNCING
      #   flash[:warning] << "#{entity_name} is already being synced right now. Please be patient and wait for the operation to finish."
      # end

      # if sync_task.gatherer.is_a?(Sync::UserDataGatherer)
      #   flash[:alert].concat(sync_task.gatherer.flash[:alert])
      #   flash[:notice].concat(sync_task.gatherer.flash[:notice])
        
      #   data_time = sync_task.task.data[Tasks::SyncTask::DATA_TIME]
      #   save_time = sync_task.task.data[Tasks::SyncTask::SAVE_TIME]
      #   total_time = data_time + save_time
      #   flash[:notice] << "Syncing of #{entity_name} took #{data_time}s + #{save_time}s = #{total_time}s, total calls: #{sync_task.gatherer.no_of_queries}"
      # end
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
