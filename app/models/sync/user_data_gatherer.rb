require 'json'
require 'cgi'
require 'uri'
#require 'ruby-prof'

module Sync
  class UserDataGatherer

    def initialize(username, facebook)
      @username = username
      @facebook = facebook
      @no_of_queries = 0
      
      @@MAX_LIMIT = 900

      @page_limit = @@MAX_LIMIT

      @call_history = {default: []}
      @call_history_index = :default
    end
    attr_writer :prev_feed_link, :page_limit
    attr_reader :no_of_queries

    def my_logger
      @my_logger ||= Logger.new("#{Rails.root}/log/#{@username}.log")
    end

    def flash
      @flash ||= {error: [], notice: []}
    end
    
    def start_fetch(pages = nil)
      #RubyProf.start
      basic_data = @facebook.get_object(@username)

      if basic_data.empty?
          # TODO
          return
      end

      @prev_feed_link = @prev_feed_link[ @prev_feed_link.index('?')+1..-1 ] if !@prev_feed_link.nil? and @prev_feed_link.index('?') > 0
      data = {
        basic_data: basic_data,
        feed: fetch_data("#{@username}/feed", @prev_feed_link, pages)
      }

      #results = RubyProf.stop
      
      #File.open "#{Rails.root}/tmp/profile-graph.html", 'w' do |file|
      #  RubyProf::GraphHtmlPrinter.new(results).print(file)
      #end

      return data
    end

    def dispatch_api_query(fb_graph_call)
      @error = nil

      # stop if same call was made before
      unless api_query_already_sent?(fb_graph_call)
        my_logger.debug "Calling '#{fb_graph_call}'..."
        begin
          result = @facebook.api(fb_graph_call)
          @no_of_queries += 1
        rescue Koala::Facebook::APIError => e
          result = { 'error' => { 'message' => e.fb_error_message, 'type' => e.fb_error_type, 'code' => e.fb_error_code } }
        rescue => e 
          result = { 'error' => { 'message' => "Ruby Exception: #{e.message}", "exception" => e } }
        end

        if result.nil?
          result = { 'error' => { 'message' => "Empty result object" } }
        end

        if result.has_key?('error')
          my_logger.error "Received Error: #{result['error']['message']}"
          my_logger.info "-- result: #{result.to_s}"
          Rails.logger.error "Error in resource #{@username}: #{result['error']['message']}"

          flash[:alert] << result.to_yaml

          @error = result['error']
        elsif @last_result != result
          @last_result = result

          my_logger.debug "Received: " + result.to_s[0..100]

          return result
        end
      end
      return false
    end
    
    private
    def fetch_data(connection, graph_link, pages)
      graph_link ||= ''
      forward = graph_link.index('since').nil?
      pages ||= -1
      
      data = []
      update_query = ''
      resume_query = ''
      @last_result = ''
      @error = nil

      fb_graph_call = "/#{connection}?" + create_next_query("", graph_link)
      
      while true
        # switch to the correct call stack
        call_history(connection)
        result = dispatch_api_query(fb_graph_call)

        # query issue
        resume_query = fb_graph_call if result == false

        unless @error.nil?
          if is_strange_facebook_error?(@error)
            # unknown FB error, try changing the query
            fb_graph_call = change_query_for_unknown_error(fb_graph_call)
          else
            break
          end
        else
          # end of data
          break if result_is_empty(result)
          
          # get comments and likes
          resume_query = fb_graph_call if get_all_comments_and_likes_for(result['data']) == false
          
          # save this link so we can continue after that point
          if update_query.empty? and result['paging'].has_key?('previous')
            update_query = result['paging']['previous']
          end

          data.concat(result['data'])
          
          fb_graph_call = "/#{connection}?" + create_next_query(forward ? result['paging']['next'] : result['paging']['previous'], graph_link)
          
          pages -= 1
          if pages == 0
            # save the next call to resume sync
            resume_query = fb_graph_call
            break
          end
        end
      end

      access_token_regexp = /access_token\=[^&]+(&|$)/
      update_query[access_token_regexp] = "" if update_query =~ access_token_regexp
      
      return {
        data: data,
        resume_query: resume_query,
        previous_link: "/#{connection}?" + create_next_query(update_query),
        error: @error
      }
    end

    def is_strange_facebook_error?(error)
      (error.has_key?('type') and error['type'] == 'OAuthException' and error.has_key?('code') and error['code'] == 1) or
      (error['message'].nil?) # we have encountered a strange issue where simply the request fails. this can be due to a too high item "limit"
    end

    def get_all_comments_and_likes_for(data)
      @error = nil
      
      data.each do |entry|
        [ get_all_comments(entry),
          get_all_likes(entry) ].each do |ok|

          if ok != true
            my_logger.debug "Stopping querying because encountered an error in sub-query"
            @error = ok
          end
        end

        break unless @error.nil?
      end

      return @error.nil?
    end

    def call_history(new_group = nil)
      unless new_group.nil?
        @call_history_index = new_group
        @call_history[ @call_history_index ] = [] if @call_history[ @call_history_index ].nil?
      end

      @call_history[ @call_history_index ]
    end

    def api_query_already_sent?(fb_graph_call)
      already_sent = call_history.include?(fb_graph_call)
      call_history.push(fb_graph_call) unless already_sent

      return already_sent
    end

    def fetch_connected_data(query, parameter)
      # fetch data for likes & comments as fast as possible
      custom_limit = @page_limit
      @page_limit = @@MAX_LIMIT

      result = fetch_data(query, parameter, nil)
      
      @page_limit = custom_limit

      return result
    end
    
    def get_all_comments(entry)
      if !entry.has_key?('comments') or entry['comments']['count'] == 0 or
          entry['comments']['count'].to_i == entry['comments']['data'].length
        return true
      end
      
      # always fetch the comments new because of possible replies
      query = entry['id'] + '/comments'
      # reset sent comments to prevent duplicates
      entry['comments']['data'] = []
      

      comments = fetch_connected_data(query, 'filter=stream')
      return comments['error'] if !comments['error'].nil?

      entry['comments']['data'].concat(comments[:data])

      return true
    end
    
    def get_all_likes(entry)
      # if we have more than 4 likes we need to call seperate api methods
      if (!entry.has_key?('like_count') or entry['like_count'] == 0) and 
         (!entry.has_key?('likes') or !entry['likes'].has_key?('count') or entry['likes']['count'] <= 4)
        return true
      end
      
      likes = fetch_connected_data(entry['id'] + '/likes', nil)
      return likes['error'] if !likes['error'].nil?
      
      entry['likes'] = {'data' => []} if !entry.has_key?('likes')
      entry['likes']['data'] = likes[:data]

      return true
    end
      
    def result_is_empty(result) 
      # if no paging array is present the return object is 
      # presumably empty
      result.blank? || !result.has_key?('paging')
    end
   
    def change_query_for_unknown_error(old_query)
      uri = URI.parse(old_query)

      orig_page_limit = @page_limit
      @page_limit = 25
      new_query = uri.path + "?" + create_next_query(nil, uri.query)
      @page_limit = orig_page_limit

      return new_query
    end

    def create_next_query(next_link, *more)
      if !next_link.nil?
        startindex = next_link.index('?') ? next_link.index('?') + 1 : 0
        next_query = next_link[ startindex..-1 ]
        uri = CGI.parse(next_query)
      else
        uri = CGI.parse("")
      end
      uri.delete('access_token')
      uri['limit'] = [@page_limit.to_s]
      
      # add additional parameters if not already present
      more_params = CGI.parse(more.join('&').to_s)
      more_params.each do |k,v|
        if !uri.has_key?(k)
          uri[k] = v
        end
      end
      
      result = uri.map{|k,v| "#{k}=#{v[0]}"}.join('&')

      # encountered a strange bug where at the end a " was added making the URI invalid
      result = result[0..-2] if result[-1] == '"'

      return result
    end
  end
end