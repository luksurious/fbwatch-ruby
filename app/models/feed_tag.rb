class FeedTag < ActiveRecord::Base
  belongs_to :feed
  belongs_to :resource
end
