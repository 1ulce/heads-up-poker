class HeadsUpRoomChannel < ApplicationCable::Channel
  
  def redis
    @redis ||= Redis.current
  end

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
    stream_from "user_#{user_id}"
    redis.rpush("user_id_list", user.user_id)
    user_list = redis.lrange("user_id_list",redis.llen("user_id_list") -2 , redis.llen("user_id_list"))
    rendered_users = "" 
    user_list.each do |u|
      yourself = true if u == user.user_id
      rendered_user = ApplicationController.renderer.render(partial: 'users/user', locals: { user: u, yourself: yourself })
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
    redis.rpush("ready_user_id_list", user_id)
    if redis.llen("ready_user_id_list") == 2
      u_names = []
      2.times do |n|
        u_name = redis.lindex("ready_user_id_list",n)
        u_names << u_name
        redis.rpush("playing_user_id_list", u_name)
        ActionCable.server.broadcast "user_#{u_name}", {action: "start"}
      end
      Poker.initial_table_setting(2, "#{u_names[0]}", "#{u_names[1]}")
      redis.del("ready_user_id_list")
      start2
    end
  end

  def clear
    redis.flushall
  end

  def start2
    p "GAME START!!!!!!!!!!!!!!!!!"
    Poker.initial_game_setting
    Poker.preflop_setting
    cards = nil
    2.times do |n|
      u_name = redis.lindex("playing_user_id_list",n)
      cards = Poker.deal_cards(Poker.get_player(u_name))
      ActionCable.server.broadcast "user_#{u_name}", {action: "deal", cards: cards}
    end
    # Poker.start
  end

end
