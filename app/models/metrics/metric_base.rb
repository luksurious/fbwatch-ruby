module Metrics
  class MetricBase
    attr_accessor :metrics, :resource, :resource_group

    def initialize(options = {})
      set_options(options)

      @metrics = []
    end

    def set_options(options)
      @resource = options[:resource]
      @resource_group = options[:resource_group]
    end

    def class_name
      self.class.name.demodulize.underscore
    end

    def make_metric_model(name, value)
      metric = Metric.where({ metric_class: self.class_name, name: name, resource_id: @resource.id }).first_or_initialize

      metric.value = value
      
      @metrics.push(metric)
    end

    def make_group_metric_model(options)
      # TODO sanity checks maybe?
      metric = GroupMetric.where({ 
        metric_class: self.class_name, 
        name: options[:name], 
        resources_token: options[:token], 
        resource_group_id: @resource_group.id 
        }).first_or_initialize

      metric.value = options[:value]

      options[:resources].each do |res|
        metric.resources << res unless metric.resources.include?(res)
      end
      metric.resources.each do |res|
        metric.resources.delete(res) unless options[:resources].include?(res)
      end

      @metrics.push(metric)
      #if !metric.save
      #  Rails.logger.error "Couldn't save metric #{options[:name]} (errors: #{metric.errors.full_messages}"
      #end
    end
  end
end