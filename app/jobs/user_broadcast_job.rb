class UserBroadcastJob < ApplicationJob
  queue_as :default

  def perform(user)
    ActionCable.server.broadcast 'heads_up_room_channel', user: render_user_id(user)
  end

  private
    def render_user_id(user)
      ApplicationController.renderer.render(partial: 'users/user', locals: { user: user })
    end
end
