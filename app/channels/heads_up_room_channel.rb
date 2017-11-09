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
    user = User.where(user_id: user_id).first || User.new
    user.user_id = user_id
    puts user.user_id
    user.save
    stream_from "user_#{user_id}"
    redis.rpush("user_id_list", user.user_id)
    user_list = redis.lrange("user_id_list",redis.llen("user_id_list") -2 , redis.llen("user_id_list"))
    rendered_users = "" 
    user_list.each do |u|
      user_list.each do |uu|
        rendered_user = ApplicationController.renderer.render(partial: 'users/user', locals: { user: uu})
        if uu == u
          ActionCable.server.broadcast "user_#{u}", { action: "join_me", users: rendered_user }
        else 
          ActionCable.server.broadcast "user_#{u}", { action: "join_rival", users: rendered_user }
        end
      end
    end

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
      ActionCable.server.broadcast "room_1", {action: "set_id", players: u_names}
      redis.del("ready_user_id_list")
      start
    end
  end

  def clear
    redis.flushall
  end

  def action(actions)
    result = Poker.process_action(actions["data"][0], actions["data"][1])
    Poker.treat_action(result)
    Poker.next_player
    Poker.check_next_street
    current_player = redis.hget(:game, :current_player).to_i
    unless redis.hget(:street, :can_next_street) == "true"
      self.finish if Poker.is_finish
      current_player = redis.hget(:game, :current_player).to_i
      if redis.hget(Poker.player(current_player), :alive) == "true" && redis.hget(Poker.player(redis.hget(:game, :current_player).to_i), :active) == "true"
        Poker.urge_action_to_web(nil, redis.hget(:street, :nofbet).to_i, redis.hget(:game, :current_bet_amount).to_i, redis.hget(Poker.player(current_player), :amount).to_i, redis.hget(Poker.player(current_player), :prev_nofbet).to_i)
      end
    else
      self.finish if Poker.is_finish
      Poker.calc_pot_from_betting_status
      Poker.postflop_setting
      puts redis.hget(Poker.player(current_player), :alive)
      puts redis.hget(Poker.player(current_player), :active)
      if redis.hget(Poker.player(current_player), :alive) == "true" && redis.hget(Poker.player(current_player), :active) == "true"
        Poker.urge_action_to_web(nil, redis.hget(:street, :nofbet).to_i, redis.hget(:game, :current_bet_amount).to_i, redis.hget(Poker.player(current_player), :amount).to_i, redis.hget(Poker.player(current_player), :prev_nofbet).to_i)
      end
    end
  end

  def finish
    Poker.end_the_game
    p "GAME END!!!!!!!!!!!!!!!!!"
    start
  end

  def start
    p "GAME START!!!!!!!!!!!!!!!!!"
    # Poker.start
    Poker.initial_game_setting
    Poker.preflop_setting
    current_player = redis.hget(:game, :current_player).to_i
    if redis.hget(Poker.player(current_player), :alive) == "true" && redis.hget(Poker.player(redis.hget(:game, :current_player).to_i), :active) == "true"
      Poker.urge_action_to_web(nil, redis.hget(:street, :nofbet).to_i, redis.hget(:game, :current_bet_amount).to_i, redis.hget(Poker.player(current_player), :amount).to_i, redis.hget(Poker.player(current_player), :prev_nofbet).to_i)
    end
  end

end
