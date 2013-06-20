require 'uri'

class ResourcesController < ApplicationController
  # GET /resources
  # GET /resources.json
  def index
    @resources = Resource.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @resources }
    end
  end

  # GET /resources/1
  # GET /resources/1.json
  def show
    @resource = Resource.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @resource }
    end
  end

  # GET /resources/new
  # GET /resources/new.json
  def new
    @resource = Resource.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @resource }
    end
  end

  # GET /resources/1/edit
  def edit
    @resource = Resource.find(params[:id])
  end

  # POST /resources
  # POST /resources.json
  def create
    #
    params[:resource][:name] = parse_facebook_url(params[:resource][:name])
    @resource = Resource.new(params[:resource])
    @resource.active = true

    success = false
    begin
      success = @resource.save
    rescue Exception => e
      if e.is_a? ActiveRecord::RecordNotUnique
        alert = 'This resource seems to be already in the database!'
      else
        alert = 'Some error occured: ' + e.message
      end
      flash[:alert] = alert
    end
    
    respond_to do |format|
      if success
        format.html { redirect_to root_path, notice: 'Resource was successfully created.' }
        format.json { render json: @resource, status: :created, location: @resource }
      else
        format.html { render :new }
        format.json { render json: @resource.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /resources/1
  # PUT /resources/1.json
  def update
    @resource = Resource.find(params[:id])

    respond_to do |format|
      if @resource.update_attributes(params[:resource])
        format.html { redirect_to @resource, notice: 'Resource was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @resource.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /resources/1
  # DELETE /resources/1.json
  def destroy
    @resource = Resource.find(params[:id])
    @resource.destroy

    respond_to do |format|
      format.html { redirect_to resources_url }
      format.json { head :no_content }
    end
  end
  
  private
  def parse_facebook_url(url)
    uri = URI.parse(url)
    
    # the path of the facebook url holds either the unique name or the facebook id
    path = uri.path.split('/')

    # if it's a page or group the id is in the last "folder"
    # otherwise this will just return the unique name
    return path[-1]
  end
end
