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
  
  # GET /resources/1
  # GET /resources/1.json
  def details
    @resource = Resource.find_by_username(params[:username])
    if @resource.nil?
      redirect_to root_path, alert: "Resource #{params[:username]} not found"
      return
    end

    @basicdata = Basicdata.find_all_by_resource_id(@resource.id)
    @feeds = Feed.order("updated_time DESC").find_all_by_resource_id(@resource.id)

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: build_detail_json }
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
    username = parse_facebook_url(params[:resource][:username])
    
    basicdata = session[:facebook].get_object(username)
    
    @resource = Resource.find_by_facebook_id(basicdata['id'])
    if @resource.nil?
      @resource = Resource.new
      @resource.facebook_id = basicdata['id']
    end
    
    @resource.username = basicdata['username']
    @resource.name = basicdata['name']
    @resource.link = basicdata['link']
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

  def build_detail_json
    # build basic structure
    json = {
      id: @resource.facebook_id,
      name: @resource.name,
      username: @resource.username,
      link: @resource.link
    }

    likes = Likes.joins(:resource).find_all_by_resource_id(@resource.id)

    # add all special values from the basicdata store
    @basicdata.each do |basic_hash|
      json[ basic_hash.key ] = basic_hash.value
    end

    likes_struct = {}
    # add all likes to the feed items
    likes.each do |like|
      if !likes_struct.has_key?(like.feed_id)
        likes_struct[ like.feed_id ] = []
      end

      likes_struct[ like.feed_id ].push({id: like.facebook_id, name: like.name, username: like.username})
    end

    # add feed items
    feed_struct = {}
    comments = []
    @feeds.each do |feed_item|

      feed_item["likes"] = {
        count: feed_item["like_count"],
        data: likes_struct[ feed_item.id ]
      }
      feed_item.delete('like_count')

      feed_item["comments"] = {
        count: feed_item["comment_count"],
        data: []
      }
      feed_item.delete('comment_count')

      if feed_item.parent_id.nil?
        feed_item.delete('parent_id')
        feed_struct[ feed_item.facebook_id ] = feed_item
      elsif feed_struct.has_key?( feed_item.parent_id )

        feed_item['comments'][:data].push(comment)

      else
        comments.push(feed_item)
      end
    end

    # add comments which couldnt be added initially
    comments.each do |comment|
      if !feed_struct.has_key?(comment.parent_id)
        logger.debug('Parent feed item of comment not found: ' + comment.id)
        next
      end

      feed_item['comments'][:data].push(comment)
    end
    
    json["feed"] = feed_struct
    
    return json
  end
end
