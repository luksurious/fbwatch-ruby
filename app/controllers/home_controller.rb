class HomeController < ApplicationController
  include SessionsHelper
  def index
    if !signed_in?
      redirect_to login_path
      return
    end
    
    @resources = Resource.all
    @resource = Resource.new

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @resources }
    end
  end
  
  def login
  end
end
