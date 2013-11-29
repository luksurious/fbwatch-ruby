require "net/http"
require "uri"
require 'sanitize'

module Metrics
  class GoogleMentions < MetricBase
    def analyze
      clear
      @logger = Logger.new("#{Rails.root}/log/google_mentions.log")

      resource_combinations(2).each do |combination|

        # calc shared resources
        combi_keywords = keywords_for(combination)

        for i in 1..5
          web_results = query_google_keywords(combi_keywords)

          break if web_results[:count] > 0
          # if absolutely no results were found wait a second and try again, there seem to be some limits for automating queries
          sleep 1
        end

        make_mutual_group_metric_model(name: 'google_mentions', value: web_results, resources: combination)
        @logger.debug "-- count #{web_results[:count]}"
      end
    end

    def keywords_for(resources)
      return [] unless resources.is_a?(Array)

      keywords = []
      resources.each do |res|
        # self.keywords is defined in MetricBase
        keywords << self.keywords[res.id][0..-2] # dont use the facebook id as a keyword, it might skew the results
      end

      keywords
    end

    def sort_value(value)
      if value.is_a?(Fixnum)
        value
      elsif value.has_key?('count') and value['count'].class.method_defined? :to_i
        value['count'].to_i
      else
        value
      end
    end

    def query_google_keywords(keywords)
      count = nil

      query_parameter = ""
      keywords.each do |group|
        query_parameter << '("' << group.join('"|"') << '") '
      end

      @logger.debug("Calling google with query: #{query_parameter}")

      response = fetch("http://www.google.com/search?hl=en&q=#{URI.escape(query_parameter)}&filter=0")

      body = response.body.encode("UTF-8", invalid: :replace, undef: :replace, replace: "")

      html_count = body.match(/id\=\"resultStats\"\>[^\<]+/)

      if html_count.nil? or html_count.length == 0
        count = 0
        @logger.debug(Sanitize.clean(body, {:remove_contents => ["script","style"]})[0..1000])
      else
        inner_html = html_count[0].match(/[0-9,\.]+/)
        
        if inner_html.nil? or inner_html.length == 0
          count = 0 
          @logger.debug(Sanitize.clean(body, {:remove_contents => ["script","style"]})[0..1000])
        else
          count = inner_html[0].gsub(/[,\.]/, '').to_i
        end
      end
      
      { count: count, query: query_parameter }
    end

    def fetch(uri_str, limit = 10)
      # You should choose a better exception.
      raise ArgumentError, 'too many HTTP redirects' if limit == 0

      response = Net::HTTP.get_response(URI(uri_str))

      case response
      when Net::HTTPSuccess then
        response
      when Net::HTTPRedirection then
        location = response['location']
        @logger.warn "redirected to #{location}"
        fetch(location, limit - 1)
      else
        @logger.warn "-- Unknown response status: #{response.class}"
        response
      end
    end
  end
end