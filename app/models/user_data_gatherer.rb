require 'json'
require 'cgi'
#require 'ruby-prof'


class UserDataGatherer
  def initialize(username, facebook)
    @username = username
    @facebook = facebook
    @no_of_queries = 0
  end
  attr_writer :prev_feed_link
  attr_reader :no_of_queries

  def my_logger
    @@my_logger ||= Logger.new("#{Rails.root}/log/#{@username}.log")
  end
  
  def start_fetch(pages)
    #RubyProf.start
    basic_data = @facebook.get_object(@username)

    if basic_data.empty?
        # TODO
        return
    end
    
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
  
  private
  def fetch_data(connection, graph_link, pages)
    graph_link ||= ''
    forward = graph_link.index('since').nil?
    pages ||= -1
    
    data = []
    call_history = []
    update_query = ''
    resume_query = ''
    fb_graph_call = "/#{connection}?" + create_next_query("", graph_link)
    last_result = ''
    
    while true
      # stop if same call was made before
      if call_history.include? fb_graph_call
        break
      end
      
      my_logger.debug "Calling '#{fb_graph_call}#'..."
      begin
        result = @facebook.api(fb_graph_call)
        @no_of_queries += 1
      rescue Exception => e
        resume_query = fb_graph_call
        # catch exceptions so that all previous data doesnt get lost
        Rails.logger.debug "Received Exception: #{e.message}"
        break
      end
      my_logger.debug "Received: " + result.to_s[0..100]
      
      if last_result == result
        break
      end
      last_result = result

      call_history.push(fb_graph_call)

      if result.nil?
        # connection or access issue
        resume_query = fb_graph_call
      end

      if result_is_empty(result)
        break
      end
      
      result['data'].each do |entry|
        get_all_comments(entry)
        get_all_likes(entry)
      end

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

    access_token_regexp = /access_token\=[^&]+(&|$)/
    update_query[access_token_regexp] = "" if update_query =~ access_token_regexp
    
    return {
      data: data,
      resume_query: resume_query,
      previous_link: "/#{connection}?" + create_next_query(update_query)
    }
  end
  
  def get_all_comments(entry)
    if !entry.has_key?('comments') or entry['comments']['count'] == 0 or
        entry['comments']['count'].to_i == entry['comments']['data'].length
      return
    end
    
    # always fetch the comments new because of possible replies
    query = entry['id'] + '/comments'
    # reset sent comments to prevent duplicates
    entry['comments']['data'] = []
    
    comments = fetch_data(query, 'filter=stream', nil)
    
    entry['comments']['data'].concat(comments[:data])
  end
  
  def get_all_likes(entry)
    # if we have more than 4 likes we need to call seperate api methods
    if (!entry.has_key?('like_count') or entry['like_count'] == 0) and 
       (!entry.has_key?('likes') or entry['likes']['count'] <= 4)
      return
    end
    
    likes = fetch_data(entry['id'] + '/likes', nil, nil)
    
    entry['likes'] = {'data' => []} if !entry.has_key?('likes')
    entry['likes']['data'] = likes[:data]
  end
    
  def result_is_empty(result) 
    # if no paging array is present the return object is 
    # presumably empty
    result.nil? or !result.has_key?('paging')
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
    uri['limit'] = ["900"]
    
    # add additional parameters if not already present
    more_params = CGI.parse(more.join('&').to_s)
    more_params.each do |k,v|
      if !uri.has_key?(k)
        uri[k] = v
      end
    end
    
    uri.map{|k,v| "#{k}=#{v[0]}"}.join('&')
  end
end
