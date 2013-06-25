class Basicdata < ActiveRecord::Base
  attr_accessible :key, :value
  
  belongs_to :resource
end
