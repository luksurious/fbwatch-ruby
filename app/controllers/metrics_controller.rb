class MetricsController < ApplicationController
  def resource
    @username = params[:username]
    @resource = Resource.find_by_username(@username)

    metric_task = Tasks::MetricTask.new(resource: @resource)

    TaskWorker.perform_async(metric_task.task.id)

    flash[:notice] << "Resource metrics are being updated"
    redirect_to resource_details_path(@resource.username)
  end

  def group
    resource_group = ResourceGroup.find(params[:id])

    metric_task = Tasks::MetricTask.new(resource_group: resource_group)

    TaskWorker.perform_async(metric_task.task.id)

    flash[:notice] << "Group and resource metrics are being updated"
    redirect_to resource_group_details_path(resource_group)
  end
end