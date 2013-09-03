class MetricsManager
  @@installed_metrics = ['ResourceStats']

  def initialize(resource)
    @resource = resource
  end

  def run_all_metrics
    metrics_transaction = []

    @@installed_metrics.each do |metric_class|
      begin
        require_relative "#{metric_class.underscore}"
      rescue LoadError
        Rails.logger.error("Failed to load metric class #{metric_class}")
      end

      klass = metric_class.constantize.new(@resource)

      metrics = klass.analyze
      metrics_transaction.concat(metrics) if metrics.is_a?(Array)
    end

    metrics_transaction.each do |obj| 
      obj.save if obj.is_a?(ActiveRecord::Base)
    end
  end
end