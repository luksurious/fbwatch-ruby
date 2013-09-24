class GroupMetric < ActiveRecord::Base
  belongs_to :resource_group
  has_and_belongs_to_many :resources, -> { order(username: :desc) }
end
