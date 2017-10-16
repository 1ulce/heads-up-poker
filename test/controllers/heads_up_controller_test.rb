require 'test_helper'

class HeadsUpControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get heads_up_show_url
    assert_response :success
  end

end
