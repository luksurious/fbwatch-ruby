class Metric < ActiveRecord::Base
  validates :name, :uniqueness => { :scope => :metric_id }

  belongs_to :resource
end