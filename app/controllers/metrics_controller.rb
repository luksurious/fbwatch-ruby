class MetricsController < ApplicationController
  def resource
    @username = params[:username]
    @resource = Resource.find_by_username(@username)

    MetricsManager.new(resource: @resource).run_resource_metrics

    redirect_to resource_details_path(@resource.username)
  end

  def group
    resource_group = ResourceGroup.find(params[:id])

    metrics = MetricsManager.new(group: resource_group)
    metrics.run_group_metrics
    metrics.run_resource_metrics

    redirect_to resource_group_details_path(resource_group)
  end
end