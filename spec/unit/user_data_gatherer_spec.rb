require 'spec_helper'

describe UserDataGatherer do
  it "should return empty result if error json received (top-level)" do
    facebook = double("koala")
    facebook.should_receive(:get_object).and_return({
      "name" => "name",
      "username" => "username",
      "link" => "link",
      "id" => "id"
    })

    api_error = { "error" => {
      "message" => "test error occured (OAuthException)",
      "code" => "17"
    }}

    facebook.should_receive(:api).with('/username/feed?limit=900').and_return(api_error)

    gatherer = UserDataGatherer.new("username", facebook)
    data = gatherer.start_fetch
    data.should have_key(:feed)
    data[:feed].should have_key(:data)
    data[:feed].should have_key(:error)
    data[:feed][:data].should eq []
    data[:feed][:error].should eq api_error["error"]

  end

  it "should fetch comments and likes" do
    class UserDataGatherer
      public :get_all_comments_and_likes_for
    end

    facebook = double("koala")
    facebook.stub(:api).and_return({ data: "some data" })
    gatherer = UserDataGatherer.new("username", facebook)

    result = gatherer.get_all_comments_and_likes_for([
      {'id' => '123', 'comments' => {'data' => [1]}, 'likes' => {'data' => [1], 'count' => 10}},
      {'id' => '456', 'comments' => {'data' => [555]}, 'likes' => {'data' => [1], 'count' => 10}}
    ])

    result.should eq true
  end

  it "should detect duplicate queries even if nested calls were made" do
    class UserDataGatherer
      public :call_history, :api_query_already_sent?
    end
    
    gatherer = UserDataGatherer.new("1", nil)

    gatherer.call_history('/1/feed')
    gatherer.api_query_already_sent?('/1/feed?limit=25').should eq false

    gatherer.call_history('/123/comments')
    gatherer.api_query_already_sent?('/123/comments?limit=25').should eq false

    gatherer.call_history('/123/likes')
    gatherer.api_query_already_sent?('/123/likes?limit=25').should eq false

    gatherer.call_history('/1/feed')
    gatherer.api_query_already_sent?('/1/feed?limit=25').should eq true
    
    gatherer.call_history('/1/feed')
    gatherer.api_query_already_sent?('/123/likes?limit=25').should eq false

  end
end