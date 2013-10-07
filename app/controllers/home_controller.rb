class HomeController < ApplicationController
  before_action :assert_auth, only: [:index]

  def index
    if params[:simple]
      index_plain
    else
      index_groups
    end
  end

  def index_groups
    @resource_groups = ResourceGroup.order(:group_name)
    @resource_group = ResourceGroup.new
    @total_groups = ResourceGroup.count

    respond_to do |format|
      format.html { render template: "home/groups" }
      format.json { render json: @resources }
    end
  end

  def index_plain
    @offset = params[:p].to_i || 0

    @resources = Resource.order('active DESC, last_synced DESC, created_at ASC').limit(100).offset(@offset * 100)
    @resource = Resource.new
    @total_res = Resource.count

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @resources }
    end
  end
end
