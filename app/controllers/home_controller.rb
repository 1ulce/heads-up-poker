class HomeController < ApplicationController
  def show
    @user_count = $redis.llen("seating_users")
  end
end
