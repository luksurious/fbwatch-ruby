class MetricsController < ApplicationController
  def resource
    background = params[:sync] != '1'

    @username = params[:username]
    @resource = Resource.find_by_username(@username)

    metric_task = Tasks::MetricTask.new(resource: @resource)

    if background
      TaskWorker.perform_async('task' => metric_task.task.id)
    else
      metric_task.resource_metrics = Metrics::MetricBase.single_metrics(params[:group_metrics].split(',').map(&:to_i)) if params[:resource_metrics]
      metric_task.run
    end

    flash[:notice] << "Resource metrics are being updated"
    redirect_to resource_details_path(@resource.username)
  end

  def group
    background = params[:sync] != '1'
    resource_group = ResourceGroup.find(params[:id])

    metric_task = Tasks::MetricTask.new(resource_group: resource_group)

    if background
      TaskWorker.perform_async('task' => metric_task.task.id)
    else
      metric_task.group_metrics = Metrics::MetricBase.group_metrics(params[:group_metrics].split(',').map(&:to_i)) if params[:group_metrics]
      metric_task.resource_metrics = Metrics::MetricBase.single_metrics(params[:group_metrics].split(',').map(&:to_i)) if params[:resource_metrics]
      metric_task.run
    end

    flash[:notice] << "Group and resource metrics are being updated"
    redirect_to resource_group_details_path(resource_group)
  end
end