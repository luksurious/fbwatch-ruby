class Task < ActiveRecord::Base
  serialize :data, JSON

  belongs_to :resource
  belongs_to :resource_group
end
