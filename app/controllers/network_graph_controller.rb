class NetworkGraphController < ApplicationController
  
  def random_color
    @color_map ||= ['#FF9000', '#BF8130', '#A65E00', '#FFAC40', '#FFC273',
                    '#FFBE00', '#BF9B30', '#A67B00', '#FFCE40', '#FFDB73',
                    '#FF4500', '#BF5730', '#A62D00', '#FF7340', '#FF9973',
                    '#0A64A4', '#24577B', '#03406A', '#3E94D1', '#65A5D1']

    @color_map.sample
  end

  def for_resource
    resource = Resource.find(params[:id])
    group = ResourceGroup.find(params[:group_id])

    group_graph(group, 'network_graph', resource)
  end

  def google_for_resource
    resource = Resource.find(params[:id])
    group = ResourceGroup.find(params[:group_id])

    group_graph(group, 'network_graph_google', resource)
  end

  def for_resource_group
    group_graph(ResourceGroup.find(params[:id]), 'network_graph')
  end

  def google_for_resource_group
    group_graph(ResourceGroup.find(params[:id]), 'network_graph_google')
  end

  def group_graph(resource_group, metric_class, resource = nil)
    json = {
      nodes: [],
      edges: []
    }

    GroupMetric.where(resource_group_id: resource_group.id, metric_class: metric_class, name: 'graph_edge').each do |metric|
      # skip malformed items
      next if metric.resources.empty?
      # if getting the graph for a specific resource skip unrelated edges
      next if !resource.nil? and metric.resources.first != resource and metric.resource != resource

      json[:edges] << {
        source: metric.resources.first.username,
        target: metric.resource.username,
        weight: [metric.value, 0].max
      }
    end

    GroupMetric.where(resource_group_id: resource_group.id, metric_class: metric_class, name: 'graph_node').each do |metric|
      json[:nodes] << {
        id: metric.resource.username,
        label: metric.resource.name,
        size: [metric.value, 0.1].max,
        color: random_color,
        forceLabel: metric.value > 5
      }
    end

    respond_to do |format|
      format.html { redirect_to resource_group_details_path(resource_group) }
      format.json { render json: json }
    end
  end
end
