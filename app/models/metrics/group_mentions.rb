module Metrics
  class GroupMentions < MetricBase
    def analyze
      # get keywords to search for
      keywords = get_keywords

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

    private
      def get_keywords
        if @keywords.nil?
          @keywords = {}
          self.resource_group.resources.each do |res|
            custom_keywords = Basicdata.where(resource_id: res.id, key: 'keywords').pluck(:value).first

            @keywords[res.id] = [
              res.name,
              res.username,
              res.facebook_id
            ]

            unless custom_keywords.nil?
              custom_keywords.split(',').each do |key|
                @keywords[res.id] << key.strip
              end
            end
          end
        end

        @keywords
      end
  end
end