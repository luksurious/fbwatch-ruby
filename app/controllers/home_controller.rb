class HomeController < ApplicationController
  include SessionsHelper
  def index
    if !signed_in?
      redirect_to login_path
      return
    end
    
    offset = params[:p] || 0

    @resources = Resource.order('active DESC, last_synced DESC').limit(100).offset(offset.to_i * 100)
    @resource = Resource.new

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @resources }
    end
  end
  
  def login
  end
end
