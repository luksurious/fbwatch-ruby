module Metrics
  class Scoring < MetricBase
    def analyze
      clear

      # bi-directional scoring
      all_metrics = GroupMetric.where(resource_group_id: @resource_group.id).where.not(metric_class: 'scoring').
                                # group by source
                                order(:resource_id).group_by(&:resource_id)
      # calc relationship score

      all_metrics.each do |res_id, group|
        metrics_by_target = {}
        # group by target
        group.each do |metric|
          metric.resources.each do |involved|
            metrics_by_target[involved.id] ||= []
            metrics_by_target[involved.id] << metric
          end
        end
        # calc directional score

        metrics_by_target.each do |target_id, metrics|
          score = calc_relationship_score(metrics)
          
          make_group_metric_model(name: 'relationship_score', value: score, resources: [Resource.find(target_id)], owner: res_id)
        end
      end

      # shared resources metrics
      #  calc geometric mean
    end

    def calc_relationship_score(metrics)
      @score = {}

      metrics.group_by(&:metric_class).each do |metric_class, values|
        klass = Metrics::ModelHelper.make_klass(metric_class).set(values)

        case metric_class
          when 'shared_resources_metric'
            analyze_shared_metrics(values)
          when 'group_mentions'
            analyze_mentions(values)
        end
      end

      @score
    end

    def analyze_shared_metrics(values)
      @score[:shared] = Stats.geometric_mean(values.map { |item| item.sort_value }).round(2)
    end

    def analyze_mentions(values)
      # there should only be one metric from group_mentions
      metric = values.first
      
      @score[:mentions] = metric.value.map do |k, x|
        modifier = 1

        modifier = 2 if k == '__tagged__' 

        modifier * x
      end.reduce(&:+)
    end

    def sort_value(value)
      value['shared'].to_f + value['mentions'].to_f
    end
  end
end