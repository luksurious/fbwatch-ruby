require 'uri'

class ResourcesController < ApplicationController
  before_action :set_resource_by_id, only: [:add_to_group, :show, :edit, :update, :destroy]
  before_action :set_resource_by_username, only: [:details, :disable, :enable, :update, :destroy]


  def add_to_group
    @resource.resource_groups << ResourceGroup.find(params[:resource][:resource_groups])
    @resource.save

    redirect_to resource_details_path(@resource.username)
  end
  
  def disable
    @resource.deactivate
    @resource.save
    
    flash[:notice] << "Disabled #{@resource.username}"
    redirect_to :back
  end
  
  def enable
    @resource.activate
    @resource.save

    flash[:notice] << "Enabled #{@resource.username}"
    redirect_to :back
  end

  # GET /resources
  # GET /resources.json
  def index
    @offset = params[:p].to_i || 0

    @resources = Resource.order('active DESC, last_synced IS NULL, last_synced DESC, created_at ASC').limit(100).offset(@offset * 100)
    @resource = Resource.new
    @total_res = Resource.count

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @resources }
    end
  end

  # GET /resources/1
  # GET /resources/1.json
  def show
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @resource }
    end
  end
  
  # GET /resources/1
  # GET /resources/1.json
  def details
    if @resource.nil?
      flash[:alert] << "Resource #{params[:username]} not found"
      redirect_to :back
      return
    end

    @basicdata = Basicdata.where(resource_id: @resource.id)
    
    if params[:format] != 'json'
      @offset = params[:p].to_i || 0
      
      filter_hash = {resource_id: @resource.id}
      @filter = params[:f]
      filter_hash[:data_type] = @filter if !@filter.nil? and !@filter.empty?

      @feeds = Feed.includes(:to, :from).order("updated_time DESC").where(filter_hash).limit(100).offset(@offset * 100)
      @filter_count = Feed.where(filter_hash).count
      @total_pages = (@filter_count / 100.0).ceil

      @metrics = Metric.where(resource_id: @resource.id)

      @group_metrics = {}
      @resource.group_metrics.each do |metric|
        @group_metrics[metric.resource_group_id] ||= []

        @group_metrics[metric.resource_group_id] << metric
      end
      @group_metrics.each do |key,group|
        @group_metrics[key] = group.sort { |a,b| b.sort_value <=> a.sort_value }
      end

      @all_groups = ResourceGroup.all

      @tasks = Task.where(resource_id: @resource.id, running: true).count

      if @resource.currently_syncing?
        flash[:info] << "This resource is currently syncing"
      end
    end
    
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
  end

  # POST /resources
  # POST /resources.json
  def create
    if params[:resource].has_key?(:username)
      username = parse_facebook_url(params[:resource][:username])
      success = create_for(username)
    elsif params[:resource].has_key?(:usernames)
      success = true
      usernames = params[:resource][:usernames].split(/\r?\n/)
      usernames.each do |username|
        create_for(parse_facebook_url(username))
      end
    else
      # TODO error handling
    end

    
    respond_to do |format|
      if success
        format.html { redirect_to :back, notice: 'Resource was successfully created.' }
        format.json { render json: @resource, status: :created, location: @resource }
      else
        format.html { render :new }
        format.json { render json: @resource.errors, status: :unprocessable_entity }
      end
    end
  end

  def create_for(username)
    if username.nil?
      flash[:notice] << 'Invalid URI provided'
      return false
    end

    begin
      basicdata = session[:facebook].get_object(username)
    rescue Koala::Facebook::ClientError => e
      flash[:alert] << "failed to create resource for #{username}. facebook returned an error: #{e.fb_error_message}"
      return false
    end
    
    @resource = Resource.find_by_facebook_id(basicdata['id'])
    if @resource.nil?
      @resource = Resource.new
      @resource.facebook_id = basicdata['id']
    end
    
    @resource.username = basicdata['username'] || basicdata['id']
    @resource.name = basicdata['name']
    @resource.link = basicdata['link']
    @resource.active = true

    success = false
    begin
      success = @resource.save
    rescue => e
      if e.is_a? ActiveRecord::RecordNotUnique
        alert = 'This resource seems to be already in the database!'
      else
        alert = 'Some error occured: ' + e.message
      end
      flash[:alert] << alert
    end

    return success
  end

  # PUT /resources/1
  # PUT /resources/1.json
  def update
    respond_to do |format|
      if @resource.update_attributes(resource_params)
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
    @resource.clear
    @resource.destroy

    respond_to do |format|
      format.html { redirect_to :back }
      format.json { head :no_content }
    end
  end
  
  def parse_facebook_url(url)
    begin
      uri = URI.parse(url)
    rescue URI::InvalidURIError => e
      logger.debug("Invalid URI provided: #{url}")
      return nil
    end
    
    # the path of the facebook url holds either the unique name or the facebook id
    path = uri.path.split('/')

    # if it's a page or group the id is in the last "folder"
    # otherwise this will just return the unique name
    return path[-1]
  end

  def build_detail_json
    load_start = Time.now
    feeds = Feed.includes(:to, :from, likes: [:resource], feed_tags: [:resource]).order("parent_id ASC, updated_time DESC").where(resource_id: @resource.id).load
    likes = Like.includes(:resource).joins(:feed).where(feeds: {resource_id: @resource.id})
    tags = FeedTag.includes(:resource).joins(:feed).where(feeds: {resource_id: @resource.id})
    load_end = Time.now

    build_start = Time.now
    # build basic structure
    json = {
      id: @resource.facebook_id,
      name: @resource.name,
      username: @resource.username,
      link: @resource.link
    }
    
    bdata_start = Time.now
    # add all special values from the basicdata store
    @basicdata.each do |basic_hash|
      json[ basic_hash.key ] = basic_hash.value
    end
    json.delete('feed_previous_link')
    json.delete('feed_last_link')
    bdata_end = Time.now

    likes_start = Time.now
    # go through all likes to setup
    all_likes = {}
    likes.each do |like|
      all_likes[like.feed_id] ||= []
      all_likes[like.feed_id] << like
    end
    likes_end = Time.now

    tags_start = Time.now
    all_tags = {}
    tags.each do |tag|
      all_tags[tag.feed_id] ||= []
      all_tags[tag.feed_id] << tag
    end
    tags_end = Time.now

    # pre-select all comments
    comments = {}

    feed_start = Time.now
    # add feed items
    feed_struct = []
    feeds.each do |feed_item|
      # feed items with a parent are comments and injected in the corresponding item
      if !feed_item.parent_id.nil?
        comments[feed_item.parent_id] ||= []
        comments[feed_item.parent_id] << feed_item
        next
      end

      feed_hash = feed_item.to_fb_hash(comments: comments, likes: all_likes, tags: all_tags)
      
      feed_struct.push(feed_hash)
    end
    feed_end = Time.now
    
    json["feed"] = feed_struct

    build_end = Time.now

    Rails.logger.info "Load time: #{load_end-load_start}, Basicdata time: #{bdata_end-bdata_start}, likes time: #{likes_end-likes_start}, tags time: #{tags_end-tags_start}, feed time: #{feed_end-feed_start}, build time: #{build_end-build_start}"
    
    return json
  end

  private
    def set_resource_by_id
      @resource = Resource.find(params[:id])
    end

    def set_resource_by_username
      @resource = Resource.where(username: params[:username]).first
    end

    def resource_params
      params[:resource].permit(:active, :facebook_id, :last_synced, :name, :username, :link)
    end
end
