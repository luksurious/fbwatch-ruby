class HomeController < ApplicationController
  def index
    @resources = Resource.all
    @resource = Resource.new

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @resources }
    end
  end
end
