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

    result = gatherer.get_all_comments_and_likes_for([{'id' => '123', 'comments' => {'data' => [1]}, 'likes' => {'data' => [1], 'count' => 10}}])

    result.should eq true
  end

end