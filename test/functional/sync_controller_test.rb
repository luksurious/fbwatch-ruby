require 'test_helper'

class SyncControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response 302
  end

  test "should get syncall" do
    get :syncall
    assert_response 302
  end

end
