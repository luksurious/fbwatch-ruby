class ApitestController < ApplicationController
  def index
    if !signed_in?
      redirect_to 'login'
      return
    end
    
    if params.has_key?(:query)
      @query = params[:query]
      fetcher = UserDataGatherer.new("apitest", session[:facebook])
      begin
        @result = fetcher.dispatch_api_query(@query)
      rescue UserDataGatherer::OAuthException => e
        flash[:error] << e.message
      end
      flash[:error].concat(fetcher.flash[:error])
      flash[:notice].concat(fetcher.flash[:notice])
    end
    
    @user = session[:facebook].get_object('me')
    @token = session[:facebook].access_token
  end
end
