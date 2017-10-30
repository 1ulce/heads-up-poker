class HeadsUpController < ApplicationController
  def show
    @users = User.first.user_id
  end
end
