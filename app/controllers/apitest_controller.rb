class ApitestController < ApplicationController
  before_action :assert_auth
  
  def index  
    if params.has_key?(:query)
      @query = params[:query]
      fetcher = Sync::UserDataGatherer.new("apitest", session[:facebook])
      begin
        @result = fetcher.dispatch_api_query(@query)
      rescue => e
        flash[:error] << e.message
      end
      flash[:error].concat(fetcher.flash[:error])
      flash[:notice].concat(fetcher.flash[:notice])
    end
    
    @user = session[:facebook].get_object('me')
    @token = session[:facebook].access_token
  end
end
