require 'test_helper'

class Public::FollowsControllerTest < ActionDispatch::IntegrationTest
  test "should get follow" do
    get public_follows_follow_url
    assert_response :success
  end

end
