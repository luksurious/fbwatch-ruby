class SessionsController < ApplicationController
  def login
  end

  def create
    sign_in auth_hash
    redirect_to root_path
  end
  
  def failure
    # TODO: tell if code expired or something else happened
    
    redirect_to login_path, alert: "Authentication failed, please try again."
  end

  protected

  def auth_hash
    request.env['omniauth.auth']
  end
end