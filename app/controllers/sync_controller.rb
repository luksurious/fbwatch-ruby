class SyncController < ApplicationController
  def index
    @username = params[:name]
    gatherer = UserDataGatherer.new(@username, session[:facebook])
    @result = gatherer.start_fetch
  end

  def syncall
  end
end
