class ApplicationController < ActionController::Base
  protect_from_forgery
  include SessionsHelper

  before_filter :setup_flash

  def setup_flash
    flash[:notice] ||= []
    flash[:error] ||= []
    flash[:warning] ||= []
  end

end
