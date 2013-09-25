class GroupMetric < ActiveRecord::Base
  belongs_to :resource_group
  has_and_belongs_to_many :resources, -> { order(username: :desc) }

  def render
    klass = self.metric_class.constantize.new(self.resource_group)
    klass.render(name: self.name, value: self.value, resources: self.resources)
  end
end
