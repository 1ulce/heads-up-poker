class HeadsUpRoomChannel < ApplicationCable::Channel

  def subscribed
    # stream_from "some_channel"
    #stream_from "heads_up_room_channel"
    stream_from "user_#{user_id}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def connect_to_table(data)
    @table = Table.find(data["table_id"])
    current_user.update(table_id: data["table_id"])
    stream_from "room_#{data["table_id"]}"
    unless table.seating_users.size >= 2
      current_user.stream({action: "show_seating_button"})
      current_user.stream({ action: "info", info: "table has seat. wanna play?"})
    else
      current_user.stream({action: "show_watch_button"})
      current_user.stream({ action: "info", info: "table is full. wanna watch?"})
    end
    check_im_on_play
  end

  def check_im_on_play
    if table.playing_users.include?(user_id)
      table.stream({ action: "info", info: "user is coming back!"})
      current_user.stream({action: "clear_seat_button"})
      table.playing_users.each do |uu|
        name = (uu == user_id ? "me" : "rival")
        rendered_user = ApplicationController.renderer.render(partial: 'users/user', locals: { id: uu, name: name })
        current_user.stream({ action: "join_#{name}", users: rendered_user })
      end
      current_user.stream({action: "set_id", players: table.playing_users.to_a})
      current_user.stream({action: "deal_hand", cards: current_user.hand.value})
      current_user.stream({action: "deal_button", id: game.button.to_i})
      current_user.stream({action: "deal_board", board: game.board.value})
      current_user.stream({action: "show_pot", pot: game.side_pot_1.to_i})
      game.users.each do |user|
        current_user.stream({action: "show_betting", id: user.seat.seat_num, betting: user.betting.to_i})
        current_user.stream({action: "show_stack", id: user.seat.seat_num, stack: user.amount.to_i})
      end
      if game.alives.include?(user_id) && game.actives.include?(user_id) && game.current_player.to_i == current_user.seat.seat_num
        game.urge_action_to_web(nil, game.bet_num.to_i, game.current_bet_amount.to_i, current_user.amount.to_i, current_user.prev_bet_num.to_i)
      end
    else
      current_user.stream({ action: "info", info: "im not playing"})
    end
  end

  def start_watching
    # not yet
    # table.watching_users << current_user.user_id
  end

  def entered
    user_list = table.seating_users
    if user_list.size < 2
      unless user_list.include?(user_id)
        current_user.stream({ action: "info", info: "seated!"})
        table.seating_users << current_user.user_id
        table.stream({ action: "render_users_count", count: user_list.size})
        user_list.each do |u|
          user_list.each do |uu|
            if uu == u
              rendered_user = ApplicationController.renderer.render(partial: 'users/user', locals: { id: uu, name: "me" })
              ActionCable.server.broadcast "user_#{u}", { action: "join_me", users: rendered_user }
            else
              rendered_user = ApplicationController.renderer.render(partial: 'users/user', locals: { id: uu, name: "rival" })
              ActionCable.server.broadcast "user_#{u}", { action: "join_rival", users: rendered_user }
            end
          end
        end

        if user_list.size == 2
          user_list.each {|u| ActionCable.server.broadcast "user_#{u}", {action: "filled"}}
          table.stream({action: "clear_seat_button"})
        end
      else
        rendered_user = ApplicationController.renderer.render(partial: 'users/user', locals: { id: uu, name: "me" })
        current_user.stream({ action: "join_me", users: rendered_user })
      end
    elsif user_list.size == 2
      if user_list.include?(user_id)
        table.stream({ action: "render_users_count", count: user_list.size})
        user_list.each do |u|
          user_list.each do |uu|
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
          table.stream({action: "clear_seat_button"})
        end
      end
    end
  end

  def put_message(data)
    table.stream(data)
  end

  def clear_table
    # $redis.flushdb #どこまで？redis-objectは消える？
    table.playing_users.clear
    table.seating_users.clear
    table.stream({action: "info", info: "someone table cleared"})
    table.stream({action: "clear_table"})

    unless table.seating_users.size >= 2
      table.stream({action: "show_seating_button"})
    end
    # table.stream({ action: "render_users_count", count: table.seating_users.size})
  end

  def stop_stream
    stop_all_streams
  end

  def ready
    ready_users = table.ready_users
    ready_users << user_id
    if ready_users.size == table.max # 今は2
      table.stream({action: "clear_ready_button"})
      playing_users = table.playing_users
      ready_users.each do |u|
        table.playing_users << u
        ActionCable.server.broadcast "user_#{u}", {action: "start"}
      end
      table.initial_table_setting(2, playing_users)
      table.stream({action: "set_id", players: playing_users.to_a})
      2.times {ready_users.pop}
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
    def current_user
      @current_user ||= User.find_or_create_by(user_id: user_id)
    end
    def table
      @table ||= current_user.table
    end
    def game
      @game ||= table.games.last
    end
end
