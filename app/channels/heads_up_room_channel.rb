class HeadsUpRoomChannel < ApplicationCable::Channel
  
  def redis
    @redis ||= Redis.current
  end

  def subscribed
    # stream_from "some_channel"
    #stream_from "heads_up_room_channel"
    stream_from "room_1"
    stream_from "user_#{user_id}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def load_page
    unless redis.llen("seating_users") >= 2
      ActionCable.server.broadcast "user_#{user_id}", {action: "show_seating_button"}
    end
  end

  def entered
    if redis.llen("seating_users") < 2
      user_list = redis.llen("seating_users").times.map {|n| redis.lindex("seating_users", n)}
      unless user_list.include?(user_id)
        ActionCable.server.broadcast "user_#{user_id}", { action: "info", info: "seated!"}
        redis.rpush("seating_users", user_id)
        user_list << user_id
        ActionCable.server.broadcast 'room_1', { action: "render_users_count", count: redis.llen("seating_users")}
        rendered_users = "" 
        user_list.each do |u|
          user_list.each do |uu|
            rendered_user = ApplicationController.renderer.render(partial: 'users/user', locals: { user: uu })
            if uu == u
              ActionCable.server.broadcast "user_#{u}", { action: "join_me", users: rendered_user }
            else 
              ActionCable.server.broadcast "user_#{u}", { action: "join_rival", users: rendered_user }
            end
          end
        end

        if user_list.count == 2
          user_list.each {|u| ActionCable.server.broadcast "user_#{u}", {action: "filled"}}
          user_list.each {|u| ActionCable.server.broadcast "room_1", {action: "clear_seat_button"}}
        end
      else
        rendered_user = ApplicationController.renderer.render(partial: 'users/user', locals: { user: user_id })
        ActionCable.server.broadcast "user_#{user_id}", { action: "join_me", users: rendered_user }
      end
    elsif redis.llen("seating_users") == 2
      user_list = redis.llen("seating_users").times.map {|n| redis.lindex("seating_users", n)}
      if user_list.include?(user_id)
        ActionCable.server.broadcast 'room_1', { action: "render_users_count", count: redis.llen("seating_users")}
        rendered_users = "" 
        user_list.each do |u|
          user_list.each do |uu|
            rendered_user = ApplicationController.renderer.render(partial: 'users/user', locals: { user: uu })
            if uu == u
              ActionCable.server.broadcast "user_#{u}", { action: "join_me", users: rendered_user }
            else 
              ActionCable.server.broadcast "user_#{u}", { action: "join_rival", users: rendered_user }
            end
          end
        end

        if user_list.count == 2
          user_list.each {|u| ActionCable.server.broadcast "user_#{u}", {action: "filled"}}
          user_list.each {|u| ActionCable.server.broadcast "room_1", {action: "clear_seat_button"}}
        end
      end
    end
  end

  def put_message(data)
    ActionCable.server.broadcast "room_1", data
  end

  def stop_stream
    stop_all_streams
  end

  def ready
    redis.rpush("ready_users", user_id)
    if redis.llen("ready_users") == 2
      ActionCable.server.broadcast 'room_1', {action: "clear_ready_button"}
      u_names = []
      2.times do |n|
        u_name = redis.lindex("ready_users",n)
        u_names << u_name
        redis.rpush("playing_users", u_name)
        ActionCable.server.broadcast "user_#{u_name}", {action: "start"}
      end
      Poker.initial_table_setting(2, "#{u_names[0]}", "#{u_names[1]}")
      ActionCable.server.broadcast "room_1", {action: "set_id", players: u_names}
      2.times {|n| redis.lpop("ready_users")}
      start
    end
  end

  def clear_table
    redis.flushdb
    ActionCable.server.broadcast "room_1", {action: "info", info: "someone table cleared"}
    ActionCable.server.broadcast "room_1", {action: "clear_table"}
    unless redis.llen("seating_users") >= 2
      ActionCable.server.broadcast "room_1", {action: "show_seating_button"}
    end
    ActionCable.server.broadcast 'room_1', { action: "render_users_count", count: redis.llen("seating_users")}
  end

  # def clear_people
  #   redis.flushdb
  # end

  def action(actions)
    result = Poker.process_action(actions["data"][0], actions["data"][1].to_i)
    Poker.treat_action(result)
    Poker.next_player
    Poker.check_next_street
    action2
  end

  def action2
    unless redis.hget(:street, :can_next_street) == "true"
      return self.finish if Poker.is_finish
      current_player = redis.hget(:game, :current_player).to_i
      if redis.hget(Poker.player(current_player), :alive) == "true" && redis.hget(Poker.player(current_player), :active) == "true"
        Poker.urge_action_to_web(nil, redis.hget(:street, :nofbet).to_i, redis.hget(:game, :current_bet_amount).to_i, redis.hget(Poker.player(current_player), :amount).to_i, redis.hget(Poker.player(current_player), :prev_nofbet).to_i)
      else
        Poker.check_next_street
        Poker.next_player
        action2
      end
    else
      return self.finish if Poker.is_finish
      Poker.calc_pot_from_betting_status
      Poker.postflop_setting
      current_player = redis.hget(:game, :current_player).to_i
      if redis.hget(Poker.player(current_player), :alive) == "true" && redis.hget(Poker.player(current_player), :active) == "true"
        Poker.urge_action_to_web(nil, redis.hget(:street, :nofbet).to_i, redis.hget(:game, :current_bet_amount).to_i, redis.hget(Poker.player(current_player), :amount).to_i, redis.hget(Poker.player(current_player), :prev_nofbet).to_i)
      else
        Poker.check_next_street
        Poker.next_player
        self.action2
      end
    end
  end

  def finish
    sleep(2)
    Poker.end_the_game
    p "GAME END!!!!!!!!!!!!!!!!!"
    self.start
  end

  def table_finish
    results = []
    2.times do |n|
      if redis.hget(Poker.player(n+1), :amount).to_i == 0
        results << "lose"
      else
        results << "win"
      end
    end
    2.times do |n| 
      user = redis.lpop("playing_users")
      ActionCable.server.broadcast "user_#{user}", {action: "show_result", result: results}
    end
    2.times {|n| redis.lpop("seating_users")}
  end

  def start
    p "GAME START!!!!!!!!!!!!!!!!!"
    # Poker.start
    Poker.initial_game_setting
    Poker.preflop_setting
    return self.table_finish if Poker.is_table_finish
    current_player = redis.hget(:game, :current_player).to_i
    if redis.hget(Poker.player(current_player), :alive) == "true" && redis.hget(Poker.player(current_player), :active) == "true"
      Poker.urge_action_to_web(nil, redis.hget(:street, :nofbet).to_i, redis.hget(:game, :current_bet_amount).to_i, redis.hget(Poker.player(current_player), :amount).to_i, redis.hget(Poker.player(current_player), :prev_nofbet).to_i)
    end
  end

end
