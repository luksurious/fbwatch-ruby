require 'active_support'

class SyncController < ApplicationController
  def index
    @username = params[:name]
    gatherer = UserDataGatherer.new(@username, session[:facebook])
    @result = gatherer.start_fetch
    @resource = Resource.find_by_username(@username)
    
    save_basic_data
    update_resource
    
    redirect_to controller: 'resources', action: 'show', id: @resource.id
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
    
    # overwrite existing values
    existing_data.each do |item|
      if new_data.has_key?(item.key)
        item.value = new_data[item.key].is_a?(Hash) ? ActiveSupport::JSON.encode(new_data[item.key]) : new_data[item.key]
        if !item.save
          flash[:alert] = 'Failed saving data for ' + item.key
        end
        new_data.delete(item.key)
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
  end
end
