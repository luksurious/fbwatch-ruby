module Sync
  class FacebookPaging < FacebookGraph
    attr_reader :base, :query_count
      
    MAX_LIMIT = 900

    def initialize(options)
      super(options[:koala])

      @start = parameters_from_url(options[:start])
      @base = options[:base]

      # if the given start link contains the keyword since, we go back in time
      @forward = @start.index('since').nil?

      @query_count = 0

      @page_limit = options[:page_limit] || MAX_LIMIT

      @call_history = {default: []}
      @call_history_index = :default

      logger = options[:logger] if options[:logger]
    end

    def next
      result = dispatch_api_query(next_path)

      @paging = result['paging']

      result
    end

    def next_path
      "/#{@base}?" + next_parameters
    end

    private

      def next_link
        return nil if @paging.is_a?('Hash')

        if @forward
          @paging['next']
        else
          @paging['previous']
        end
      end

      def next_parameters(base_query)
        uri = parameters_from_url(next_link)

        uri.delete('access_token')
        uri['limit'] = [@page_limit.to_s]
        
        # add additional parameters if not already present
        more_params = CGI.parse(base_query)
        @start.merge(more_params).each do |k, v|
          if !uri.has_key?(k)
            uri[k] = v
          end
        end
        
        result = uri.map{|k,v| "#{k}=#{v[0]}"}.join('&')

        # encountered a strange bug where at the end a " was added making the URI invalid
        result = result[0..-2] if result[-1] == '"'

        return result
      end

      def parameters_from_url(url)
        next_query = ""
        if !url.nil?
          startindex = url.index('?') ? url.index('?') + 1 : 0
          next_query = url[ startindex..-1 ]
        end
        
        CGI.parse(next_query)
      end

      # returns a StandardError if an exception occurred during the query
      # returns false if the query was sent twice or the same result was received twice in succession
      # otherwise returns the result object
      def dispatch_api_query(fb_graph_call)
        # stop if same call was made before
        unless api_query_already_sent?(fb_graph_call)
          result = query(fb_graph_call)
          @query_count += 1

          if is_strange_facebook_error?(result)
            # unknown FB error, try changing the query
            result = dispatch_api_query(change_query_for_unknown_error(fb_graph_call))
          end

          if @last_result != result
            @last_result = result

            return result
          end
        end
        # sent the same query twice or
        # received the same result twice in succession
        return false
      end

      def api_query_already_sent?(fb_graph_call)
        already_sent = @call_history.include?(fb_graph_call)
        @call_history.push(fb_graph_call) unless already_sent

        already_sent
      end

      def is_strange_facebook_error?(exception)
        exception.is_a?(Koala::Facebook::APIError) and exception.fb_error_code == 1 or
        exception.is_a?(ConnectionError)
        # (error['message'].nil?) or # we have encountered a strange issue where simply the request fails. this can be due to a too high item "limit"
      end

      def change_query_for_unknown_error(old_query)
        uri = URI.parse(old_query)

        orig_page_limit = @page_limit
        @page_limit = 25
        new_query = uri.path + "?" + next_parameters(nil, uri.query)
        @page_limit = orig_page_limit

        return new_query
      end
  end
end