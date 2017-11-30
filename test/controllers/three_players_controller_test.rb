require 'test_helper'

class ThreePlayersControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get three_players_show_url
    assert_response :success
  end

end
