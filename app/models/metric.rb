class Metric < ActiveRecord::Base
  serialize :value, JSON
  
  belongs_to :resource
end