
class MetricsController < ApplicationController
  def run
    if !signed_in?
      redirect_to login_path
      return
    end

    @username = params[:username]
    @resource = Resource.find_by_username(@username)

    MetricsManager.new(@resource).run_all_metrics

    redirect_to resource_details_path(@resource.username)
  end
end