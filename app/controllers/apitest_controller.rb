class ApitestController < ApplicationController
  before_action :assert_auth
  
  def index  
    if params.has_key?(:query)
      @query = params[:query]

      tester = Resource.new
      tester.username = "apitest"

      fetcher = Sync::UserDataGatherer.new(tester, session[:facebook])
      begin
        @result = fetcher.dispatch_api_query(@query)
      rescue => e
        flash[:alert] << e.message
      end
      flash[:alert].concat(fetcher.flash[:alert])
      flash[:notice].concat(fetcher.flash[:notice])
    end
    
    @user = session[:facebook].get_object('me')
    @token = session[:facebook].access_token
  end
end
