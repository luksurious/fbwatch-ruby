require "net/http"
require "uri"
require 'sanitize'
require 'watir-webdriver'

module Metrics
  class GoogleMentions < MetricBase
    user_agents = [
      'Mozilla/5.0 (Windows NT 6.1; WOW64; rv:25.0) Gecko/20100101 Firefox/25.0',
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/32.0.1664.3 Safari/537.36',
      'Mozilla/5.0 (Windows NT 6.0) yi; AppleWebKit/345667.12221 (KHTML, like Gecko) Chrome/23.0.1271.26 Safari/453667.1221',
      'Mozilla/5.0 (compatible; MSIE 10.0; Windows NT 6.1; Trident/6.0)',
      'Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; Trident/5.0; chromeframe/13.0.782.215)',
      'Opera/12.80 (Windows NT 5.1; U; en) Presto/2.10.289 Version/12.02'
    ]

    def analyze
      clear
      @logger = Logger.new("#{Rails.root}/log/google_mentions.log")

      resource_combinations(2).each do |combination|
        @retries = 0

        # calc shared resources
        web_results = query_google_keywords(keywords_for(combination))

        make_mutual_group_metric_model(name: 'google_mentions', value: web_results, resources: combination)
        @logger.debug "-- count #{web_results[:count]}"

        # wait for some time to avoid detection
        sleep Random.rand(0..30)
      end
      
      unless @watir_browser.nil?
        @watir_browser.close
        @headless.destroy if @headless
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

      url = "http://www.google.com/search?hl=en&q=#{URI.escape(query_parameter)}&filter=0&ie=utf-8&oe=utf-8"

      # count = get_hits_directly(url)
      count = get_hits_from_browser(url)

      { count: count, query: query_parameter }
    end

    def get_hits_from_browser(url)
      b = self.watir_browser
      b.goto url

      if b.div(id: "resultStats").exists?
        return b.div(id: "resultStats").text.gsub(/[,\.]/, '').to_i
      
      if b.url.index("sorry/IndexRedirect")
        # bot activity detected
        @logger.warn "-- google detected bot activity, pause for #{wait_time} minutes"
        sleep wait_time * 60
        @retries += 1
        return get_hits_from_browser(url)
      end

      0
    end

    def watir_browser
      if @watir_browser.nil?
        begin
          require 'headless'
          @headless = Headless.new
          @headless.start
        rescue LoadError => e
        end

        @watir_browser = Watir::Browser.new
      end

      @watir_browser
    end

    def get_hits_directly(url)
      response = fetch(url)

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

      count
    end

    def fetch(uri_str, limit = 10)
      # You should choose a better exception.
      raise ArgumentError, 'too many HTTP redirects' if limit == 0

      uri = URI(uri_str)
      req = Net::HTTP::Get.new(uri)

      req['User-Agent'] = 'ELinks/0.9.3 (textmode; Linux 2.6.9-kanotix-8 i686; 127x41)'
      req['Accept'] = 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
      req['Accept-Language'] = 'en-us,en'
      req['Accept-Encoding'] = 'Accept-Encoding: deflate'
      req['Cache-Control'] = 'max-age=0'

      response = Net::HTTP.start(uri.hostname, uri.port) do |http|
        http.request(req)
      end

      case response
      when Net::HTTPSuccess then
        response
      when Net::HTTPRedirection then
        location = response['location']

        if location.index('sorry/IndexRedirect')
          # was detected
          @logger.warn "-- google detected bot activity, pause for #{wait_time} minutes"
          sleep wait_time * 60
          @retries += 1
          fetch(uri_str)
        else
          @logger.warn "redirected to #{location}"
          fetch(location, limit - 1)
        end
      else
        @logger.warn "-- Unknown response status: #{response.class}"
        response
      end
    end

    def wait_time
      @retries ||= 1
      if @retries <= 1
        30
      elsif @retries <= 5
        10
      else
        5
      end
    end
  end
end