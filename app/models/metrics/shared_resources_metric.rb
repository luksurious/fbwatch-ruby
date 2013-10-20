module Metrics
  class SharedResourcesMetric < MetricBase
    def analyze
      resource_combinations(2).each do |combination|

        # calc shared resources
        token = get_combination_token(combination)

        # users posting on or posted on by owner for both resources
        post_result = Resource.find_by_sql [post_intersection_sql, combination[0].id, combination[1].id]
        make_group_metric_model(name: 'shared_resources', token: token, value: post_result, resources: combination)


        # users having liked a post/comment on both feeds
        like_result = Resource.find_by_sql [like_intersection_sql, combination[0].id, combination[1].id]
        make_group_metric_model(name: 'shared_resources_likes', token: token, value: like_result, resources: combination)


        # users having liked a post/comment on both feeds
        tag_result = Resource.find_by_sql [tag_intersection_sql, combination[0].id, combination[1].id]
        make_group_metric_model(name: 'shared_resources_tagged', token: token, value: tag_result, resources: combination)

        # intersection of users having either liked on or posted on (or being posted on) both feeds
        mixed_result = Resource.find_by_sql [any_intersection_sql, combination[0].id, combination[0].id, combination[0].id, combination[1].id, combination[1].id, combination[1].id]
        make_group_metric_model(name: 'shared_resources_any', token: token, value: mixed_result, resources: combination)
      end
    end

    def vars_for_render(options)
      value = options[:value] || []

      shared_resources = value.map { |hash| Resource.find(hash['id']) }

      # return a hash
      {
        shared_resources: shared_resources
      }
    end

    def sort_value(value)
      res_array = value || []
      res_array.size 
    end

    def empty?(value)
      value.empty?
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
          SELECT DISTINCT resources.id
          FROM resources 
            INNER JOIN feeds 
              ON feeds.from_id = resources.id 
                OR feeds.to_id = resources.id 
          WHERE feeds.resource_id = ?) 
        A INNER JOIN (
          SELECT DISTINCT resources.id
          FROM resources 
            INNER JOIN feeds 
              ON feeds.from_id = resources.id 
                OR feeds.to_id = resources.id 
          WHERE feeds.resource_id = ?) 
        B ON A.id = B.id"
      end

      def like_intersection_sql
        "SELECT A.id FROM (
          SELECT DISTINCT resources.id FROM resources INNER JOIN likes ON likes.resource_id = resources.id INNER JOIN feeds ON feeds.id = likes.feed_id
          WHERE feeds.resource_id = ?) A
        INNER JOIN
        (SELECT DISTINCT resources.id FROM resources INNER JOIN likes ON likes.resource_id = resources.id INNER JOIN feeds ON feeds.id = likes.feed_id
          WHERE feeds.resource_id = ?) B
        ON A.id = B.id"
      end

      def tag_intersection_sql
        "SELECT A.id FROM (
          SELECT DISTINCT resources.id FROM resources INNER JOIN feed_tags ON feed_tags.resource_id = resources.id INNER JOIN feeds ON feeds.id = feed_tags.feed_id
          WHERE feeds.resource_id = ?) A
        INNER JOIN
        (SELECT DISTINCT resources.id FROM resources INNER JOIN feed_tags ON feed_tags.resource_id = resources.id INNER JOIN feeds ON feeds.id = feed_tags.feed_id
          WHERE feeds.resource_id = ?) B
        ON A.id = B.id"
      end

      def any_intersection_sql
        "SELECT DISTINCT A.id FROM (
          SELECT DISTINCT resources.id FROM resources INNER JOIN likes ON likes.resource_id = resources.id INNER JOIN feeds ON feeds.id = likes.feed_id
          WHERE feeds.resource_id = ?
          UNION
          SELECT DISTINCT resources.id FROM resources INNER JOIN feed_tags ON feed_tags.resource_id = resources.id INNER JOIN feeds ON feeds.id = feed_tags.feed_id
          WHERE feeds.resource_id = ?
          UNION
          SELECT DISTINCT resources.id 
          FROM resources 
            INNER JOIN feeds 
              ON feeds.from_id = resources.id 
                OR feeds.to_id = resources.id 
          WHERE feeds.resource_id = ?
        ) A
        INNER JOIN
        (
          SELECT DISTINCT resources.id FROM resources INNER JOIN likes ON likes.resource_id = resources.id INNER JOIN feeds ON feeds.id = likes.feed_id
          WHERE feeds.resource_id = ?
          UNION
          SELECT DISTINCT resources.id FROM resources INNER JOIN feed_tags ON feed_tags.resource_id = resources.id INNER JOIN feeds ON feeds.id = feed_tags.feed_id
          WHERE feeds.resource_id = ?
          UNION
          SELECT DISTINCT resources.id
          FROM resources 
            INNER JOIN feeds 
              ON feeds.from_id = resources.id 
                OR feeds.to_id = resources.id 
          WHERE feeds.resource_id = ?
        ) B
        ON A.id = B.id"
      end
  end
end