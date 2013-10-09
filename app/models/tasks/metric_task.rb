module Tasks
  class MetricTask < Base
    @@resource_metrics = ['ResourceStats']
    @@group_metrics = ['SharedResourcesMetric']

    def name
      'metric'
    end

    def init_data
    end

    protected
      def task_run

        if @task.resource.is_a?(Resource)
          @total_parts = @@resource_metrics.length

          result = calc_metrics_for_resource(@task.resource)

        elsif @task.resource_group.is_a?(ResourceGroup)
          @total_parts = @task.resource_group.resources.length * (@@resource_metrics.length + @@group_metrics.length)

          result = []

          @task.resource_group.resources.each do |resource|
            result << calc_metrics_for_resource(resource)
          end

          result << run_group_metrics

        else
          raise 'Invalid options provided for MetricTask to run'
        end

        return result
      end

      def run_group_metrics
        metrics_transaction = []

        @@group_metrics.each do |metric_class|
          # begin
          #   require_relative "#{metric_class.underscore}"
          # rescue LoadError
          #   Rails.logger.error("Failed to load metric class #{metric_class}")
          # end

          metric_class = "Metrics::#{metric_class}"

          klass = metric_class.constantize.new(@task.resource_group)

          metrics = klass.analyze
          metrics_transaction.concat(metrics) if metrics.is_a?(Array)

          part_done
        end

        metrics_transaction.each do |obj| 
          obj.save if obj.is_a?(ActiveRecord::Base)
        end
      end

      def calc_metrics_for_resource(resource)
        metrics_transaction = []

        @@resource_metrics.each do |metric_class|
          # begin
          #   require_relative "#{metric_class.underscore}"
          # rescue LoadError
          #   Rails.logger.error("Failed to load metric class #{metric_class}")
          #   next
          # end

          metric_class = "Metrics::#{metric_class}"
          klass = metric_class.constantize.new(resource)

          metrics = klass.analyze
          metrics_transaction.concat(metrics) if metrics.is_a?(Array)

          part_done
        end

        metrics_transaction.each do |obj| 
          obj.save if obj.is_a?(ActiveRecord::Base)
        end
      end

      def resume
      end
  end
end