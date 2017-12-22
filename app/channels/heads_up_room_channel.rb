class HeadsUpRoomChannel < ApplicationCable::Channel

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
            # rendered_user = ApplicationController.renderer.render(partial: 'users/user', locals: { user: uu })
            if uu == u
              rendered_user = ApplicationController.renderer.render(partial: 'users/user', locals: { id: uu, name: "me" })
              ActionCable.server.broadcast "user_#{u}", { action: "join_me", users: rendered_user }
            else 
              rendered_user = ApplicationController.renderer.render(partial: 'users/user', locals: { id: uu, name: "rival" })
              ActionCable.server.broadcast "user_#{u}", { action: "join_rival", users: rendered_user }
            end
          end
        end

        if user_list.count == 2
          user_list.each {|u| ActionCable.server.broadcast "user_#{u}", {action: "filled"}}
          user_list.each {|u| ActionCable.server.broadcast "room_1", {action: "clear_seat_button"}}
        end
      else
        rendered_user = ApplicationController.renderer.render(partial: 'users/user', locals: { id: uu, name: "me" })
        ActionCable.server.broadcast "user_#{user_id}", { action: "join_me", users: rendered_user }
      end
    elsif redis.llen("seating_users") == 2
      user_list = redis.llen("seating_users").times.map {|n| redis.lindex("seating_users", n)}
      if user_list.include?(user_id)
        ActionCable.server.broadcast 'room_1', { action: "render_users_count", count: redis.llen("seating_users")}
        rendered_users = "" 
        user_list.each do |u|
          user_list.each do |uu|
            # rendered_user = ApplicationController.renderer.render(partial: 'users/user', locals: { user: uu })
            if uu == u
              rendered_user = ApplicationController.renderer.render(partial: 'users/user', locals: { id: uu, name: "me" })
              ActionCable.server.broadcast "user_#{u}", { action: "join_me", users: rendered_user }
            else 
              rendered_user = ApplicationController.renderer.render(partial: 'users/user', locals: { id: uu, name: "opp" })
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

  def clear_table
    redis.flushdb
    ActionCable.server.broadcast "room_1", {action: "info", info: "someone table cleared"}
    ActionCable.server.broadcast "room_1", {action: "clear_table"}
    unless redis.llen("seating_users") >= 2
      ActionCable.server.broadcast "room_1", {action: "show_seating_button"}
    end
    ActionCable.server.broadcast 'room_1', { action: "render_users_count", count: redis.llen("seating_users")}
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
      table.initial_table_setting(2, "#{u_names[0]}", "#{u_names[1]}")
      ActionCable.server.broadcast "room_1", {action: "set_id", players: u_names}
      2.times {|n| redis.lpop("ready_users")}
      game.start
    end
  end

  def action(actions)
    result = game.process_action(actions["data"][0], actions["data"][1].to_i)
    game.treat_action(result)
    game.next_player
    game.check_next_street
    game.action
  end

  private 
    def redis
      @redis ||= Redis.current
    end

    def table
      @table ||= Table.new
    end

    def game
      @game ||= Game.new
    end
end
