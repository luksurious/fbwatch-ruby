require 'json'
require 'cgi'

class UserDataGatherer
  def initialize(username, facebook)
    @username = username
    @facebook = facebook
  end
  attr_writer :prev_feed_link
  
  def start_fetch
    basic_data = @facebook.get_object(@username)

    if basic_data.empty?
        # TODO
        return
    end

    data = {
      basic_data: basic_data,
      feed: fetch_data('feed')
    }
    
    return data
  end
  
  private
  def fetch_data(connection)
    data = []
    call_history = []
    previous_link = ''
    fb_graph_call = create_next_query(@prev_feed_link, connection)

    while true
      # TODO possibly make more robust
      # if same query was sent before break
      if call_history.include? fb_graph_call
        break
      end

      result = @facebook.api(fb_graph_call)
      call_history.push(fb_graph_call)

      if result_is_empty(result)
        break
      end

      # save this link so that we can get only updates next time
      if previous_link.empty?
        previous_link = result['paging']['previous']
      end

      data.concat(result['data'])

      fb_graph_call = create_next_query(
        @prev_feed_link ? result['paging']['previous'] : result['paging']['next'], 
        connection
      )
    end

    return {
      data: data,
      call_history: call_history,
      previous_link: previous_link
    }
  end
    
  def result_is_empty(result) 
    # if no paging array is present the return object is 
    # presumably empty
    return !result.has_key?('paging')
  end
 
  def create_next_query(next_link, connection)
    if !next_link.nil?
      startindex = next_link.index('?') ? next_link.index('?') + 1 : 0
      next_query = next_link[ startindex..-1 ]
      uri = CGI.parse(next_query)
    else
      uri = CGI.parse("")
    end

    result = "/#{@username}/#{connection}?" + (uri.has_key?('limit') ? 'limit=' + uri['limit'][0] + '&' : '') + (uri.has_key?('until') ? 'until=' + uri['until'][0] : '') + (uri.has_key?('since') ? 'since=' + uri['since'][0] : '')
    return result
  end
end
