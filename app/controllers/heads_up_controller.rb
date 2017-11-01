class HeadsUpController < ApplicationController
  def show
    @users = User.all
  end
end
