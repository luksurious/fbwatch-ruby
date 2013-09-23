class MetricBase
  def initialize(id, resource)
    @id = id
    @resource = resource
    @metrics = []
  end

  def make_metric_model(name, desc, value)
    metric = ::Metric.where({ metric_id: @id, name: name }).first
    metric = ::Metric.new if metric.nil?

    metric.metric_id = @id
    metric.name = name
    metric.description = desc
    metric.value = value
    metric.resource = @resource

    @metrics.push(metric)
  end

  def get_metrics
    return @metrics
  end
end