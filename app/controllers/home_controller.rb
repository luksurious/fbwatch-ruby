class HomeController < ApplicationController
  before_action :assert_auth, only: [:index]

  def index
    #if params[:simple]
    #  index_plain
    #else
      index_groups
    #end
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
end
