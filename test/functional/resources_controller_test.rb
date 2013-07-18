require 'test_helper'

class ResourcesControllerTest < ActionController::TestCase
  setup do
    @resource = resources(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:resources)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create resource" do
    # TODO
  end

  test "should show resource" do
    get :show, id: @resource
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @resource
    assert_response :success
  end

  test "should update resource" do
    put :update, id: @resource, resource: { active: @resource.active, facebook_id: @resource.facebook_id, last_synced: @resource.last_synced, name: @resource.name, username: @resource.username, link: @resource.link }
    assert_redirected_to resource_path(assigns(:resource))
  end

  test "should destroy resource" do
    assert_difference('Resource.count', -1) do
      delete :destroy, id: @resource
    end

    assert_redirected_to resources_path
  end

  test "facebook uri parser with normal url" do
    username = @controller.parse_facebook_url("https://facebook.com/lukebrueckner")

    assert_equal(username, "lukebrueckner")
  end

  test "facebook uri parser with ugly url" do
    username = @controller.parse_facebook_url("https://www.facebook.com/pages/Denkwerk-Zukunft-Stiftung-kulturelle-Erneuerung/432755780122579")

    assert_equal(username, "432755780122579")
  end
end
