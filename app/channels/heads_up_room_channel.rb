class HeadsUpRoomChannel < ApplicationCable::Channel
  def subscribed
    # stream_from "some_channel"
    #stream_from "heads_up_room_channel"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def entered
    stream_from "room_1"
    user = User.new
    user.user_id = user_id
    puts user.user_id
    user.save   
    Redis.current.rpush("user_id_list", user.user_id)
    user_list = Redis.current.lrange("user_id_list",Redis.current.llen("user_id_list") -2 , Redis.current.llen("user_id_list"))
    rendered_users = "" 
    user_list.each do |user|
      rendered_user = ApplicationController.renderer.render(partial: 'users/user', locals: { user: user })
      rendered_users = rendered_users + rendered_user
    end
    ActionCable.server.broadcast 'room_1', { action: "join", users: rendered_users }
    if user_list.count == 2
      ActionCable.server.broadcast 'room_1', {action: "filled"}
    end
  end

  def finished
  end

  def put_message(data)
    ActionCable.server.broadcast "room_1", data
  end

  def stop_stream
    stop_all_streams
  end

  def start
    sleep(1)
    ActionCable.server.broadcast 'room_1', { action: "finished" }
  end

  def ready
    Redis.current.sadd("ready_user_id_list", user_id)
    if Redis.current.scard("ready_user_id_list") == 2
      start
      Redis.current.del("ready_user_id_list")
    end
  end
end
