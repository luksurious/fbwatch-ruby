class ResourceGroup < ActiveRecord::Base
  has_and_belongs_to_many :resources, -> { order('active DESC, last_synced IS NULL, last_synced DESC, created_at ASC') }

  def currently_syncing?
    Tasks::SyncTask.get_for(resource_group: self).count > 0
  end

  def metric_overview_classes(resource)
    res = []
    Metrics::MetricBase.group_metrics.each do |group_metric|
      klass = Metrics::ModelHelper.make_klass(group_metric)
      next unless klass.show_in_overview

      klass.set_options(resource_group: self)
      klass.set(GroupMetric.where(resource_id: resource.id, resource_group_id: self.id, metric_class: klass.class_name).sort_by(&:sort_value).reverse)

      res << klass
    end

    res
  end
end