module Metrics
  class SingleUsersMetric < MetricBase
    @@id = "single_users_metric"

    def initialize(resource)
      super(id: @@id, resource: resource)
      @resource = resource
    end

    def analyze
      fans = Resource.joins('INNER JOIN feeds ON feeds.from_id = resources.id').where(feeds: {resource_id: @resource.id}).
                      where.not(id: @resource.id).limit(10).group('resources.id').count(:id)
      make_metric_model('fans', 'Biggest Fans by Posts', fans)

      fans_self = Resource.joins('INNER JOIN feeds ON feeds.resource_id = resources.id').where(feeds: {from_id: @resource.id}).
                           where.not(feeds: {resource_id: @resource.id}).limit(10).group('resources.id').count(:id)
      make_metric_model('fans_self', 'Feeds active on', fans_self)

      fans_like = Like.joins(:feed).where(feeds: {resource_id: @resource.id}).group('likes.resource_id').count(:id)
      make_metric_model('fans_like', 'Likers on feed', fans_like)

      feeds_i_like = Feed.joins(:likes).where(likes: {resource_id: @resource.id}).where.not(resource_id: @resource.id).group('feeds.resource_id').count(:id)
      make_metric_model('feeds_i_like', 'Feeds I liked', feeds_i_like)

      fans_tag = FeedTag.joins(:feed).where(feeds: {resource_id: @resource.id}).group('feed_tags.resource_id').count(:id)
      make_metric_model('fans_tag', 'Tags on feed', fans_tag)

      feeds_i_tag = Feed.joins(:feed_tags).where(feed_tags: {resource_id: @resource.id}).where.not(resource_id: @resource.id).group('feeds.resource_id').count(:id)
      make_metric_model('feeds_i_tag', 'Feeds I am tagged', feeds_i_tag)
    end
  end
end