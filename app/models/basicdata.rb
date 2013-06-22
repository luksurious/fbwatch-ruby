class Basicdata < ActiveRecord::Base
  attr_accessible :email, :first_name, :gender, :hometown, :hometown_id, :last_name, :link, :locale, :location, :location_id, :name, :timezone, :updated_time, :username, :verified
  
  belongs_to :resource
end
