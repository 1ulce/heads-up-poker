class HomeController < ApplicationController
  def show
    @user_count = Table.find(1).seating_users.count
  end
end
