class GroupMetric < ActiveRecord::Base
  include Metrics::ModelHelper

  belongs_to :resource_group
  has_and_belongs_to_many :resources, -> { order(username: :desc) }

  def klass
    super do |options|
      options[:resource_group] = self.resource_group
    end
  end

  def vars_for_render
    {
      involved_resources: self.resources
    }.merge(super)
  end
end
