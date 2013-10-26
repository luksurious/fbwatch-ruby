module Metrics
  class GroupMentions < MetricBase
    def analyze
      self.resource_group.resources.each do |res|
        # search feed for each keyword
        keywords.each do |partner, list|
          # save each keyword count
          combination = [res, Resource.find(partner)]
          token = get_combination_token(combination)
          
          mention_value = {
            for: partner,
            has: {}
          }

          list.each do |keyword|

            count = Feed.where(resource_id: res.id).where.not(from_id: res.id).where("data LIKE '%#{keyword}%'").count

            mention_value[:has][keyword] = count if count > 0
          end

          make_group_metric_model(name: 'mentions', token: token, value: mention_value, resources: [res]) unless mention_value[:has].blank?
        end
      end
    end

    def sort_value(value)
      mentions = 0
      value['has'].each do |k,v|
        mentions += v
      end

      mentions
    end

  end
end