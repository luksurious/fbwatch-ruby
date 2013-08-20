require 'spec_helper'

describe UserDataGatherer do
  it "should return if error json received" do
    facebook = double("koala")
    facebook.should_receive(:get_object).and_return({
      "name" => "name",
      "username" => "username",
      "link" => "link",
      "id" => "id"
    })

    api_error = { "error" => {
      "message" => "error occured (OAuthException)",
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
end