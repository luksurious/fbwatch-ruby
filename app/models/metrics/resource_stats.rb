module Metrics
  class ResourceStats < MetricBase
    @@id = "resource_stats"

    def initialize(resource)
      super(id: @@id, resource: resource)
      @resource = resource
    end

    def analyze
      total_feed = Feed.where(resource_id: @resource.id).count
      make_metric_model('total_feed_items', 'Total Feed Items', total_feed)

      posts_count = Feed.where({resource_id: @resource.id, from_id: @resource.id, data_type: "message"}).count
      make_metric_model('posts_by_owner', 'Posts made by Owner', posts_count)

      posts_by_others_count = Feed.where({resource_id: @resource.id, data_type: "message"}).where.not(from_id: @resource.id).count
      make_metric_model('posts_by_others', 'Posts made by Others', posts_by_others_count)

      story_count = Feed.where({resource_id: @resource.id, data_type: "story"}).count
      make_metric_model('story_count', 'Stories', story_count)

      resource_count = Feed.where(resource_id: @resource.id).distinct.count(:from_id)
      make_metric_model('resources_on_feed', 'Resources Posted on Feed', resource_count)

      resource_like_count = Like.joins(:feed).where(feeds: {resource_id: @resource.id}).distinct.count(:resource_id)
      make_metric_model('resource_like_count', 'Resources Liked a Post', resource_like_count)

      total_likes = Like.joins(:feed).where(feeds: {resource_id: @resource.id}).count
      make_metric_model('total_likes', 'Total Likes Received', total_likes)

      total_likes_given = Like.where(resource_id: @resource.id).count
      make_metric_model('total_likes_given', 'Total Likes Given', total_likes_given)

      total_tags = FeedTag.joins(:feed).where(feeds: {resource_id: @resource.id}).count
      make_metric_model('total_tags', 'Total Tags on Feed', total_tags)

      total_tagged = FeedTag.where(resource_id: @resource.id).count
      make_metric_model('total_tagged', 'Total Tagged', total_tagged)

      feed_type_stats('link')
      feed_type_stats('photo')
      feed_type_stats('status')
      feed_type_stats('comment')
      feed_type_stats('video')
      feed_type_stats('swf')
      feed_type_stats('checkin')
    end

    def feed_type_stats(type)
      total = Feed.where(resource_id: @resource.id, feed_type: type).count
      make_metric_model("total_#{type}", "Total #{type.capitalize.pluralize}", total)

      total_own = Feed.where(resource_id: @resource.id, feed_type: type, from_id: @resource.id).count
      make_metric_model("total_own_#{type}", "Total #{type.capitalize.pluralize} by self", total_own)

      total_else = Feed.where(feed_type: type, from_id: @resource.id).where.not(resource_id: @resource.id).count
      make_metric_model("total_else_#{type}", "Total #{type.capitalize.pluralize} by self on other Feeds", total_else)
    end
  end
end