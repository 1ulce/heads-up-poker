class HeadsUpController < ApplicationController
  def show
    @users = User.all
    Redis.current.set("testkey", ['a','ab',2])
  end
end
