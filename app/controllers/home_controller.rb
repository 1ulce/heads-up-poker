class HomeController < ApplicationController
  def show
    @user_count = Redis.current.llen("seating_users")
  end
end
