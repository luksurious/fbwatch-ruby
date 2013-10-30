module Metrics
  class GroupWeightedOverlap < MetricBase
    def analyze
      clear

      shared_metrics = GroupMetric.where(metric_class: 'shared_resources_metric', resource_group_id: self.resource_group.id)

      shared_metrics.group_by { |item| item.resources.map(&:id).sort.join('_') }.each do |key, metrics|
        post_result = []
        like_result = []
        tag_result = []
        mixed_result = []

        combination = nil

        metrics.each do |metric|
          case metric.name
            # since everything will be twice skip the second metric
            when 'shared_resources'
              post_result = metric.value if post_result.empty?
            when 'shared_resources_likes'
              like_result = metric.value if like_result.empty?
            when 'shared_resources_tagged'
              tag_result = metric.value if tag_result.empty?
            when 'shared_resources_any'
              mixed_result = metric.value if mixed_result.empty?
          end

          combination = metric.resources if combination.nil?
        end

        if mixed_result.empty?
          Rails.logger.warn "encountered malformed metrics group, key #{key}"
          next
        end

        # now look for frequency of interaction on both sides for weight
        posts_weighted = {}
        post_result.each do |res_id|
          comments = []
          posts = []

          combination.each do |target|
            typed_frequency = Feed.where(resource_id: target).where("from_id = :id OR to_id = :id", id: res_id).group(:data_type).count(:id)
            comments << typed_frequency['comment']
            posts << typed_frequency['message']
          end

          # weigh posts twice as heavy as comments
          posts_weighted[res_id] = {
            comments: comments,
            posts: posts,
            score: (Stats.geometric_mean(comments) * 1 + Stats.geometric_mean(posts) * 2).round(2)
          }
        end

        all_likes = Like.includes(:feed).where(feeds: {resource_id: combination.map {|x| x.id}}, resource_id: like_result).group_by(&:resource_id)
        likes_weighted = calc_weighted_feed_addon(all_likes, {
          owner_post: 3,
          other_post: 1,
          owner_comment: 2,
          other_comment: 1
        })

        all_tags = FeedTag.includes(:feed).where(feeds: {resource_id: combination.map {|x| x.id}}, resource_id: tag_result).group_by(&:resource_id)
        tags_weighted = calc_weighted_feed_addon(all_tags, {
          owner_post: 2,
          other_post: 1,
          owner_comment: 2,
          other_comment: 1
        })

        # now combine all
        weighted_result = {}
        mixed_result.each do |res_id|
          weighted_result[res_id] = {
            posts: posts_weighted[res_id],
            likes: likes_weighted[res_id].to_f.round(2),
            tags: tags_weighted[res_id].to_f.round(2),
            total: (posts_weighted[res_id][:score].to_f * 5 + likes_weighted[res_id].to_f * 3 + tags_weighted[res_id].to_f * 1).round(2)
          }
        end

        make_mutual_group_metric_model(name: 'weighted_overlap', value: weighted_result, resources: combination)
      end
    end

    def vars_for_renderx(options)
      if @vars_for_render.nil?
        value = options[:value] || []

        ids_to_load = value.map { |hash| 
          # backward compatibility
          if hash.is_a?(Array)
            hash.first
          elsif hash.is_a?(Hash)
            hash['id']
          else
            hash
          end
        }
        shared_resources = Resource.find(ids_to_load.compact)

        # return a hash
        @vars_for_render = {
          friendly_name: @@friendly_names[options[:name]],
          shared_resources: shared_resources
        }
      end
      @vars_for_render
    end

    def sort_value(value)
      value.map { |k,v| v['total'] }.reduce(&:+)
    end

    def empty?(value)
      value.empty?
    end

    private
      def calc_weighted_feed_addon(collection, weights)
        weighted = {}

        collection.each do |res_id, addons|
          addon_detail = {}

          addons.each do |addon|
            addon_detail[addon.feed.resource_id] ||= 0

            if addon.feed.parent_id.nil?
              if addon.feed.from_id == addon.feed.resource_id
                addon_detail[addon.feed.resource_id] += weights[:owner_post]
              else
                addon_detail[addon.feed.resource_id] += weights[:other_post]
              end
            else
              if addon.feed.from_id == addon.feed.resource_id
                addon_detail[addon.feed.resource_id] += weights[:owner_comment]
              else
                addon_detail[addon.feed.resource_id] += weights[:other_comment]
              end
            end
          end

          weighted[res_id] = Stats.geometric_mean(addon_detail.map { |type, weight| weight })
        end

        weighted
      end
  end
end