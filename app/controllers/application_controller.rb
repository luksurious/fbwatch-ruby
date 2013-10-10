class ApplicationController < ActionController::Base
  protect_from_forgery
  include SessionsHelper

  before_filter :setup_flash

  def setup_flash
    flash[:info] ||= []
    flash[:notice] ||= []
    flash[:alert] ||= []
    flash[:warning] ||= []
  end
  
  def redirect_to(*args)
    flash.keep
    super
  end
end
