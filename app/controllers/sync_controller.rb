class SyncController < ApplicationController
  def index
    @username = params[:name]
    gatherer = UserDataGatherer.new(@username, session[:facebook])
    @result = gatherer.start_fetch
    @resource = Resource.find_by_name(@username)
    
    save_basic_data
    update_resource
  end

  def syncall
  end
  
  private
  def update_resource
    @resource.facebook_id = @result[:basic_data]['id']
    @resource.last_synced = DateTime.now
    if !@resource.save
      flash[:alert] = 'Failed updating the resource'
    end
  end
  
  def save_basic_data
    # TODO doesnt work for pages!
    basic_data = Basicdata.find_by_resource_id(@resource.id)
    if basic_data.nil?
      basic_data = Basicdata.new
    end
    
    basic_data.attributes = @result[:basic_data]
    basic_data.hometown = @result[:basic_data]['hometown']['name']
    basic_data.hometown_id = @result[:basic_data]['hometown']['id']
    basic_data.location = @result[:basic_data]['location']['name']
    basic_data.location_id = @result[:basic_data]['location']['id']
    basic_data.resource = @resource
    
    if basic_data.save
      flash[:notice] = 'Basic data saved!'
    else
      flash[:alert] = 'Failed saving basic data'
    end
  end
end
