require "net/http"
require "uri"

module Metrics
  class GoogleMentions < MetricBase
    def analyze
      clear

      base_value = 0
      mentions = {}
      resource_combinations(2).each do |combination|

        # calc shared resources
        web_results = query_google_keywords(keywords_for(combination))

        make_mutual_group_metric_model(name: 'google_mentions', value: web_results, resources: combination)

        mentions[combination[0].id] ||= {}
        mentions[combination[0].id][combination[1].id] = web_results

        base_value = web_results if base_value < web_results
      end

      mentions.each do |first_id, second_level|
        second_level.each do |second_id, value|
          make_mutual_group_metric_model(name: 'google_edges', value: (value / base_value).ceil * 100, resources: [Resource.find(first_id), Resource.find(second_id)])
        end
      end
    end

    def keywords_for(resources)
      return [] unless resources.is_a?(Array)

      keywords = []
      resources.each do |res|
        # self.keywords is defined in MetricBase
        keywords << self.keywords[res.id]
      end

      keywords
    end

    def sort_value(value)
      if value.class.method_defined? :to_i
        value.to_i
      else
        value
      end
    end

    def query_google_keywords(keywords)
      query_parameter = ""
      keywords.each do |group|
        query_parameter << '("' << group.join('"|"') << '") '
      end

      Rails.logger.debug("Calling google with query: #{query_parameter}")

      uri = URI.parse("http://www.google.com/search?hl=en&q=#{URI.escape(query_parameter)}&filter=0")
      response = Net::HTTP.get_response(uri)

      html_count = response.body.match(/id\=\"resultStats\"\>[^\<]+/)

      return 0 if html_count.nil? or html_count.length == 0

      inner_html = html_count[0].match(/[0-9,\.]+/)

      return 0 if inner_html.nil? or inner_html.length == 0
      
      inner_html[0].gsub(/[,\.]/, '').to_i
    end
  end
end