module Metrics
  class MetricBase
    def initialize(options)
      @id = options[:id]
      @resource = options[:resource]
      @resource_group = options[:resource_group]
      @class = options[:class].to_s

      @metrics = []
    end

    def make_metric_model(name, desc, value)
      metric = Metric.where({ metric_id: @id, name: name, resource_id: @resource.id }).first_or_initialize

      metric.description = desc
      metric.value = value
      
      @metrics.push(metric)
    end

    def make_group_metric_model(options)
      # TODO sanity checks maybe?
      metric = GroupMetric.where({ metric_class: @class, name: options[:name], resources_token: options[:token] }).first_or_initialize

      metric.metric_class = @class
      metric.name = options[:name]
      metric.value = options[:value]
      metric.resource_group = @resource_group

      options[:resources].each do |res|
        metric.resources << res unless metric.resources.include?(res)
      end
      metric.resources.each do |res|
        metric.resources.delete(res) unless options[:resources].include?(res)
      end

      # @metrics.push(metric)
      if !metric.save
        Rails.logger.error "Couldn't save metric #{options[:name]} (errors: #{metric.errors.full_messages}"
      end
    end

    def get_metrics
      return @metrics
    end
  end
end