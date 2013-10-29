require "net/http"
require "uri"

module Metrics
  class GoogleMentions < MetricBase
    def analyze
      clear

      resource_combinations(2).each do |combination|

        # calc shared resources
        web_results = query_google_keywords(keywords_for(combination))

        make_mutual_group_metric_model(name: 'google_mentions', value: web_results, resources: combination)
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