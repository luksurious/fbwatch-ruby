require 'test_helper'

class SyncControllerControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
  end

  test "should get syncall" do
    get :syncall
    assert_response :success
  end

end
