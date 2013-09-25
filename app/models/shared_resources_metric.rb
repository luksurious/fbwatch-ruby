require 'digest/md5'

class SharedResourcesMetric < MetricBase
  def initialize(resource_group)
    @resource_group = resource_group

    super(resource_group: @resource_group, class: self.class)
  end

  def resource_combinations
    @resource_group.resources.to_a.combination(2).to_a
  end

  def analyze
    resource_combinations.each do |combination|

      # calc shared resources

      # users posting on or posted on by owner for both resources
      post_result = Resource.find_by_sql [post_intersection_sql, combination[0].id, combination[1].id]
      shared_resources = post_result.to_json

      # save metric
      token = Digest::MD5.hexdigest(combination.map{ |res| "#{res.id}.#{res.username}"  }.join('_'))
      make_group_metric_model(name: 'shared_resources', token: token, value: shared_resources, resources: combination)


      # users having liked a post/comment on both feeds
      like_result = Resource.find_by_sql [like_intersection_sql, combination[0].id, combination[1].id]
      make_group_metric_model(name: 'shared_resources_likes', token: token, value: like_result.to_json, resources: combination)

      # intersection of users having either liked on or posted on (or being posted on) both feeds
      mixed_result = Resource.find_by_sql [any_intersection_sql, combination[0].id, combination[0].id, combination[1].id, combination[1].id]
      make_group_metric_model(name: 'shared_resources_any', token: token, value: mixed_result.to_json, resources: combination)

    end

    get_metrics
  end

  def render(options)
      
    value = options[:value] || []
    resources = options[:resources] || []

    shared_resources_raw = JSON.load(value)
    shared_resources = shared_resources_raw.map { |hash| Resource.find(hash['id']) }
    shared_resources_string = shared_resources.map { |res| res.name }.join(', ')

    involved_resources_string = resources.map do |res| 
      next if res == options[:for]

      "#{res.username}" if res.is_a?(Resource) 
    end.compact.join(', ')

    html = '<p><b>'

    case options[:name]
    when 'shared_resources'
      html += "Shared users with posts"
    when 'shared_resources_likes'
      html += "Shared users with likes"
    when 'shared_resources_any'
      html += "Shared users with posts or likes"
    end

    html += "</b></p><p>with #{involved_resources_string}: #{shared_resources.size} <br><span>(#{shared_resources_string})</span></p>"
  end

  def vars_for_render(options)
    value = options[:value] || []

    shared_resources_raw = JSON.load(value)
    shared_resources = shared_resources_raw.map { |hash| Resource.find(hash['id']) }

    {
      shared_resources: shared_resources
    }
  end

  private
    def post_intersection_sql

      # NOTE: The following query and comment was first used, but later exchanged because it was faster locally, but slower online
      # DO NOT add .count to the query like that. It would be really slow!
      # If a direct count is necessary remove the .distinct method and move to .select('DISTINCT resources.id').count
      # Only other acceptable version is #.count(:id, distinct: true), which is now deprecated though
      # result = Resource.distinct.select(resources: :id).joins('INNER JOIN feeds feed1 ON feed1.from_id = resources.id OR feed1.to_id = resources.id',
      #  'INNER JOIN feeds feed2 ON feed2.from_id = resources.id OR feed2.to_id = resources.id').
      #  where(feed1: {resource_id: }, feed2: {resource_id: 257})

      "SELECT A.id FROM (
        SELECT DISTINCT resources.* 
        FROM resources 
          INNER JOIN feeds 
            ON feeds.from_id = resources.id 
              OR feeds.to_id = resources.id 
        WHERE feeds.resource_id = ?) 
      A INNER JOIN (
        SELECT DISTINCT resources.* 
        FROM resources 
          INNER JOIN feeds 
            ON feeds.from_id = resources.id 
              OR feeds.to_id = resources.id 
        WHERE feeds.resource_id = ?) 
      B ON A.id = B.id"
    end

    def like_intersection_sql
      "SELECT A.id FROM (
        SELECT DISTINCT resources.* FROM resources INNER JOIN likes ON likes.resource_id = resources.id INNER JOIN feeds ON feeds.id = likes.feed_id
        WHERE feeds.resource_id = ?) A
      INNER JOIN
      (SELECT DISTINCT resources.* FROM resources INNER JOIN likes ON likes.resource_id = resources.id INNER JOIN feeds ON feeds.id = likes.feed_id
        WHERE feeds.resource_id = ?) B
      ON A.id = B.id"
    end

    def any_intersection_sql
      "SELECT DISTINCT A.id FROM (
        SELECT DISTINCT resources.* FROM resources INNER JOIN likes ON likes.resource_id = resources.id INNER JOIN feeds ON feeds.id = likes.feed_id
        WHERE feeds.resource_id = ?
        UNION
        SELECT DISTINCT resources.* 
        FROM resources 
          INNER JOIN feeds 
            ON feeds.from_id = resources.id 
              OR feeds.to_id = resources.id 
        WHERE feeds.resource_id = ?
      ) A
      INNER JOIN
      (
        SELECT DISTINCT resources.* FROM resources INNER JOIN likes ON likes.resource_id = resources.id INNER JOIN feeds ON feeds.id = likes.feed_id
        WHERE feeds.resource_id = ?
          UNION
        SELECT DISTINCT resources.* 
        FROM resources 
          INNER JOIN feeds 
            ON feeds.from_id = resources.id 
              OR feeds.to_id = resources.id 
        WHERE feeds.resource_id = ?
      ) B
      ON A.id = B.id"
    end
end