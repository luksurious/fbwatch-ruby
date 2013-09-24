class MetricsManager
  @@resource_metrics = ['ResourceStats']
  @@group_metrics = ['SharedResourcesMetric']

  def initialize(options)
    @resource = options[:resource] || nil
    @resource_group = options[:group] || nil

    raise "Missing initializing resource or group" if @resource.nil? and @resource_group.nil?
  end

  def run_group_metrics
    metrics_transaction = []

    @@group_metrics.each do |metric_class|
      begin
        require_relative "#{metric_class.underscore}"
      rescue LoadError
        Rails.logger.error("Failed to load metric class #{metric_class}")
      end

      klass = metric_class.constantize.new(@resource_group)

      metrics = klass.analyze
      metrics_transaction.concat(metrics) if metrics.is_a?(Array)
    end

    metrics_transaction.each do |obj| 
      obj.save if obj.is_a?(ActiveRecord::Base)
    end
  end

  def run_resource_metrics
    # if initialized for a single resource
    unless @resource.nil?
      return calc_metrics_for_resource(@resource)
    end

    # if initialized for a resource group
    @resource_group.resources.each do |resource|
      calc_metrics_for_resource(resource)
    end
  end

  def calc_metrics_for_resource(resource)
    metrics_transaction = []

    @@resource_metrics.each do |metric_class|
      begin
        require_relative "#{metric_class.underscore}"
      rescue LoadError
        Rails.logger.error("Failed to load metric class #{metric_class}")
      end

      klass = metric_class.constantize.new(resource)

      metrics = klass.analyze
      metrics_transaction.concat(metrics) if metrics.is_a?(Array)
    end

    metrics_transaction.each do |obj| 
      obj.save if obj.is_a?(ActiveRecord::Base)
    end
  end
end