class ResourceStats < MetricBase
  @@id = "resource_stats"

  def initialize(resource)
    super(@@id, resource)
    @resource = resource
  end

  def analyze
    total_feed = Feed.where(resource_id: @resource.id).count
    make_metric_model('total_feed_items', 'Total Feed Items', total_feed)

    posts_count = Feed.where({resource_id: @resource.id, from_id: @resource.id, data_type: "message"}).count
    make_metric_model('posts_by_owner', 'Posts made by Owner', posts_count)

    comment_count = Feed.where({resource_id: @resource.id, feed_type: "comment"}).count
    make_metric_model('comment_count', 'Comments on Posts', comment_count)

    resource_count = Feed.where(resource_id: @resource.id).distinct.count(:from_id)
    make_metric_model('resources_on_feed', 'Resources Posted on Feed', resource_count)

    resource_like_count = Like.joins(:feed).where(feeds: {resource_id: @resource.id}).distinct.count(:resource_id)
    make_metric_model('resource_like_count', 'Resources Liked a Post', resource_like_count)

    return get_metrics
  end
end