class MetricsController < ApplicationController
  def resource
    @username = params[:username]
    @resource = Resource.find_by_username(@username)

    Tasks::MetricTask.new(resource: @resource).run

    redirect_to resource_details_path(@resource.username), notice: "Resource metrics updated"
  end

  def group
    resource_group = ResourceGroup.find(params[:id])

    Tasks::MetricTask.new(resource_group: resource_group).run

    redirect_to resource_group_details_path(resource_group), notice: "Group and resource metrics updated"
  end
end