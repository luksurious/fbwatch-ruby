class NetworkGraphController < ApplicationController
  
  def random_color
    @color_map ||= ['#FF9000', '#BF8130', '#A65E00', '#FFAC40', '#FFC273',
                    '#FFBE00', '#BF9B30', '#A67B00', '#FFCE40', '#FFDB73',
                    '#FF4500', '#BF5730', '#A62D00', '#FF7340', '#FF9973',
                    '#0A64A4', '#24577B', '#03406A', '#3E94D1', '#65A5D1']

    @color_map.sample
  end

  def for_resource_group
    resource_group = ResourceGroup.find(params[:id])
    json = {
      nodes: [],
      edges: []
    }

    GroupMetric.where(resource_group_id: params[:id], metric_class: 'network_graph', name: 'graph_node').each do |metric|
      json[:nodes] << {
        id: metric.resource.username,
        label: metric.resource.name,
        size: [metric.value, 1].max,
        color: random_color,
        forceLabel: metric.value > 5
      }
    end

    GroupMetric.where(resource_group_id: params[:id], metric_class: 'network_graph', name: 'graph_edge').each do |metric|
      next if metric.resources.empty?
      json[:edges] << {
        source: metric.resources.first.username,
        target: metric.resource.username,
        weight: [metric.value, 1].max
      }
    end

    respond_to do |format|
      format.html { redirect_to resource_group_details_path(resource_group) }
      format.json { render json: json }
    end
  end
end