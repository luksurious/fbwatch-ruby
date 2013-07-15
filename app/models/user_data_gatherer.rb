require 'json'
require 'cgi'
#require 'ruby-prof'


class UserDataGatherer
  def initialize(username, facebook)
    @username = username
    @facebook = facebook
  end
  attr_writer :prev_feed_link
  
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
    fb_graph_call = "/#{connection}?" + create_next_query(graph_link)
    
    while true
      # stop if same call was made before
      if call_history.include? fb_graph_call
        break
      end
      
      Rails.logger.debug "Calling '#{fb_graph_call}#'..."
      begin
        result = @facebook.api(fb_graph_call)
      rescue Exception => e
        resume_query = fb_graph_call
        # catch exceptions so that all previous data doesnt get lost
        Rails.logger.debug "Received Exception: #{e.message}"
        break
      end
      Rails.logger.debug "Received: #{result[0..100]}"

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
      
      fb_graph_call = "/#{connection}?" + create_next_query(forward ? result['paging']['next'] : result['paging']['previous'])
      
      pages -= 1
      if pages == 0
        # save the next call to make to resume sync
        resume_query = fb_graph_call
        break
      end
    end

    access_token_regexp = /access_token\=[^&]+(&|$)/
    update_query[access_token_regexp] = "" if update_query =~ access_token_regexp
    
    return {
      data: data,
      resume_query: resume_query,
      previous_link: update_query
    }
  end
  
  def get_all_comments(entry)
    if !entry.has_key?('comments') or entry['comments']['count'] == 0 or
        entry['comments']['count'].to_i == entry['comments']['data'].length
      return
    end
    
    if entry['comments'].has_key?('paging') and entry['comments']['paging'].has_key?('next')
      # sometimes some comments are returned and then also the link to more comments
      query = entry['comments']['paging']['next']
      query = query[ query.index('facebook.com/') + 13..-1 ]
    else
      # sometimes no comments are returned in the feed but only the amount
      query = entry['id'] + '/comments'
      # reset sent comments to prevent duplicates
      entry['comments']['data'] = []
    end
    
    comments = fetch_data(query, nil, nil)
    
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
 
  def create_next_query(next_link)
    if !next_link.nil?
      startindex = next_link.index('?') ? next_link.index('?') + 1 : 0
      next_query = next_link[ startindex..-1 ]
      uri = CGI.parse(next_query)
    else
      uri = CGI.parse("")
    end
    uri.delete('access_token')
    uri['limit'] = ["100"]
    
    uri.map{|k,v| "#{k}=#{v[0]}"}.join('&')
  end
end
