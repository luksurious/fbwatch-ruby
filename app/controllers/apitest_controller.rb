class ApitestController < ApplicationController
  include SessionsHelper
  def index
    if !signed_in?
      redirect_to 'login'
    end
    
    if params.has_key?(:query)
      @query = params[:query]
      @result = session[:facebook].api(@query)
    end
    
    @user = session[:facebook].get_object('me')
    @token = session[:facebook].access_token
  end
end
