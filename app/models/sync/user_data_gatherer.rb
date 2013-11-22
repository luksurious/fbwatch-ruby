require 'json'
require 'cgi'
require 'uri'
require 'date'

module Sync
  class UserDataGatherer < FacebookGraph
    attr_writer :page_limit
    attr_reader :no_of_queries, :username

    def initialize(resource, facebook)
      super(facebook)

      @resource = resource
      @username = resource.username
      
      @no_of_queries = 0
      
      @page_limit = nil
      @error = nil

      logger = Logger.new("#{Rails.root}/log/#{@username}.log")
    end

    def flash
      @flash ||= {alert: [], notice: []}
    end

    def fetch(pages = nil)
      fetch_basic_data

      fetch_feed

      {
        basic_data: @basic_data,
        feed: @posts,
        resume_path: @resume_path,
        error: @error
      }
    end

    private
    def fetch_feed
      resume_query = @resource.resume_query

      # if error in comments or likes construct

      scan_feed(graph_link: , pages: pages) if @error.nil?
    end

    def fetch_basic_data
      begin
        basic_data = self.facebook.get_object(@username)
      rescue => exception
        @error = exception
      end
      
      if basic_data.empty?
        error_msg = "Unable to retrieve basic information for #{@username}, result was empty" 
        logger.warn error_msg
        @error = StandardError.new(error_msg)
      end

      @basic_data = basic_data
    end

    def save_post(post)
      @posts ||= []
      
      @posts << post
    end

    def set_graph_path_to_resume(path)
      @resume_path = path
    end

    def scan_feed(options)
      @feed_pager = FacebookPaging.new(start: options[:graph_link] || '', base: "#{@resource.facebook_id}/feed", koala: facebook, logger: logger, page_limit: @page_limit)
      
      pages = options[:pages] || -1

      # clear global states when starting a scan
      @error = nil
      
      while true
        page_result = fetch_feed_page

        break if page_result[:status] != QUERY_SUCCESS

        pages -= 1
        if pages == 0
          # save the next call to resume sync
          set_graph_path_to_resume(@feed_pager.next_path)
          break
        end
      end

      @no_of_queries += @feed_pager.query_count
      
      {
        data: @posts,
        error: @error
      }
    end

    QUERY_SUCCESS = "QUERY_SUCCESS"
    QUERY_ERROR = "QUERY_ERROR"
    QUERY_END = "QUERY_END"

    def fetch_feed_page
      status = nil

      result = @feed_pager.next

      # query issue
      if result.is_a?(StandardError)
        Rails.logger.warn "Query issue for call '#{@feed_pager.last_path}'"
        set_graph_path_to_resume(@feed_pager.last_path)
        @error = result
        status = QUERY_ERROR
      end

      # end of data 
      status = QUERY_END if result_is_empty(result)
      
      # get comments and likes
      status = QUERY_ERROR unless get_all_comments_and_likes_for(result['data']).nil?
      
      if status == QUERY_ERROR
        Rails.logger.error "Error in resource #{@username}: #{result.inspect}"

        flash[:alert] << result.to_yaml
      end 

      {
        result: result,
        status: status || QUERY_SUCCESS
      }
    end

    def scan_post_attribute(base, parameters)
      pager = FacebookPaging.new(start: parameters, base: base, koala: facebook, logger: logger, page_limit: FacebookPaging.MAX_LIMIT)

      attributes = []

      while true
        result = pager.next

        break if result_is_empty(result) or result.is_a?(StandardError)

        attributes.concat(result['data'])
      end

      @no_of_queries += pager.query_count
      
      {
        'count': attributes.length,
        'data': attributes
      }
    end

    def get_all_comments_and_likes_for(data)
      error = nil
      
      data.each do |entry|
        comments = get_all_comments(entry)
        if comments.is_a?(StandardError)
          error = comments
          build_resume_path_from_entry(entry)
          break
        end

        likes = get_all_likes(entry)
        if likes.is_a?(StandardError)
          error = likes
          build_resume_path_from_entry(entry)
          break
        end

        entry['comments'] = comments
        entry['likes'] = likes

        save_post(entry)
      end

      error
    end

    def build_resume_path_from_entry(entry)
      entry_time = DateTime.strptime(entry['created_time'], "%Y-%m-%dT%H:%M:%S%z")

      time_modifier = @feed_pager.forward ? "since" : "until"

      set_graph_path_to_resume("/#{@resource.facebook_id}/feed?#{time_modifier}=#{entry_time.strftime("%s")}")
    end

    def fetch_connected_data(query, parameter)
      result = scan_post_attribute(query, parameter, nil)

      if result.is_a?(StandardError)
        logger.debug "Stopping querying because encountered an error in sub-query"
      end

      return result
    end
    
    def get_all_comments(entry)
      if !entry.has_key?('comments') or entry['comments']['count'] == 0 or
          entry['comments']['count'].to_i == entry['comments']['data'].length
        return true
      end
      
      # always fetch the comments new because of possible replies
      query = entry['id'] + '/comments'

      fetch_connected_data(query, 'filter=stream')
    end
    
    def get_all_likes(entry)
      # if we have more than 4 likes we need to call seperate api methods
      if (!entry.has_key?('like_count') or entry['like_count'] == 0) and 
         (!entry.has_key?('likes') or !entry['likes'].has_key?('count') or entry['likes']['count'] <= 4)
        return true
      end
      
      fetch_connected_data(entry['id'] + '/likes', nil)
    end
      
    def result_is_empty(result) 
      # if no paging array is present the return object is 
      # presumably empty
      result.blank? || !result.has_key?('paging')
    end
  end
end