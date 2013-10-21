module Metrics
  class FeedTimeline < MetricBase
    def analyze
      # data_type = message, so we don't get comments on photos the user is tagged later on
      first_activity = Feed.where(resource_id: self.resource.id, data_type: 'message').order(:created_time).pluck(:created_time).first
      make_metric_model('first_feed_activity', first_activity)

      # data_type = message, so we don't get "x has joined facebook" (which is a story)
      first_post = Feed.where(resource_id: self.resource.id, from_id: self.resource.id, data_type: 'message').order(:created_time).pluck(:created_time).first
      make_metric_model('first_feed_post', first_post)

      latest_activity = Feed.where(resource_id: self.resource.id).order(:created_time).pluck(:created_time).last
      make_metric_model('latest_feed_activity', latest_activity)

      latest_post = Feed.where(resource_id: self.resource.id, from_id: self.resource.id).order(:created_time).pluck(:created_time).last
      make_metric_model('latest_feed_post', latest_post)
    end

    def group_collection
      if @timeline.nil?
        @timeline = {}

        @metrics.each do |item|
          @timeline[item.name] = DateTime.parse(item.value).to_time
        end
      end

      @timeline
    end

    def first_activity
      group_collection['first_feed_activity']
    end

    def first_post
      group_collection['first_feed_post']
    end

    def last_activity
      group_collection['latest_feed_activity']
    end

    def last_post
      group_collection['latest_feed_post']
    end

    def timeline_base
      @timeline_base ||= Time.now - first_activity
    end

    def first_activity_width
      @first_activity_width ||= ((first_post - first_activity) / timeline_base * 75.0).ceil
    end

    def first_post_width
      @first_post_width ||= ((last_post - first_post) / timeline_base * 75.0).floor
    end

    def last_post_width
      @last_post_width ||= ((last_activity - last_post) / timeline_base * 75.0).ceil
    end

    def last_activity_width
      @last_activity_width ||= ((Time.now - last_activity) / 1.month * 25).ceil
    end

    def idle_width
      @idle_width ||= 25 - last_activity_width
    end
  end
end