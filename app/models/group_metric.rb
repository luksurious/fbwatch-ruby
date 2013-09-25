class GroupMetric < ActiveRecord::Base
  belongs_to :resource_group
  has_and_belongs_to_many :resources, -> { order(username: :desc) }

  def klass
    @klass ||= self.metric_class.constantize.new(self.resource_group)
  end

  def vars_for_render
    # klass.render(name: self.name, value: self.value, resources: self.resources)
    {
      name: self.name,
      involved_resources: self.resources
    }.merge(klass.vars_for_render(value: self.value))
  end

  def sort_value
    klass.sort_value(self.value)
  end
end
