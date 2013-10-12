module Tasks
  class MetricTask < Base
    @@resource_metrics = ['ResourceStats', 'SingleUsersMetric']
    @@group_metrics = ['SharedResourcesMetric']

    def self.type_name
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
          @total_parts = @task.resource_group.resources.length * @@resource_metrics.length + @@group_metrics.length

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
        run_metric_collection(metrics: @@group_metrics, resource_group: @task.resource_group)
      end

      def calc_metrics_for_resource(resource)
        run_metric_collection(metrics: @@resource_metrics, resource: resource)
      end

      def run_metric_collection(options)
        collection = options[:metrics] || []
        entity = options[:resource] || options[:resource_group]

        if entity.nil?
          Rails.logger.warn "Missing entity in MetricTask with provided options: #{options}"
          return
        end

        metrics_transaction = []

        collection.each do |metric_class|
          metric_class = "Metrics::#{metric_class}"
          klass = metric_class.constantize.new(entity)

          begin
            klass.analyze
          rescue => ex
            Utility.log_exception(ex, mail: @send_mail, info: @task.inspect)
          end

          metrics_transaction.concat(klass.metrics) if klass.metrics.is_a?(Array)

          part_done
        end

        metrics_transaction.each do |obj| 
          obj.save if obj.is_a?(ActiveRecord::Base)
        end
      end

      def resume
        raise 'MetricTasks cannot be resumed at this moment'
      end
  end
end