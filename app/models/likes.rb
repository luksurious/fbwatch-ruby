class Likes < ActiveRecord::Base
  belongs_to :resource
  belongs_to :feed
end
