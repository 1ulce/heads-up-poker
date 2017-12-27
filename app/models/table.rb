class Table < ApplicationRecord
  #after_create_commit { UserBroadcastJob.perform_later self }
  # attr_accessor :title, :price
  include Redis::Objects
  set :seating_users
  set :ready_users
  set :playing_users
  counter :played_count

  has_many :games
  has_many :users
  has_many :seats


  # def redis
  #   @redis ||= Redis.current
  # end

  def push_info(string)
    p string
    @users.each do |user|
      user.stream({action: "info", info: string})
    end
  end

  def max
    2
  end

  def stream(data, to = "room_#{self.id}")
    raise if self.id != 1
    ActionCable.server.broadcast to, data
  end
  # def name
  # end
  # def game_type 
     
  # end
  # def sit
    
  # end
  # def watch
    
  # end
  # def status
  # end
  # def get_sitting_users
    
  # end
  # def get_sitting_user()
    
  # end
  # def player(int)
  #   "player_#{int}".to_sym
  # end

  # def get_player_num(player_name)
  #   9.times do |n|
  #     u_name = redis.hget("player_#{n+1}".to_sym, :name)
  #     if player_name == u_name
  #       return n+1
  #     end
  #     n + 1
  #   end
  #   raise
  # end

  # def get_player_name(int)
  #   redis.hget(player(int), :name)
  # end

  def initial_table_setting(nofplayers = nil, user_names)
    p "initial_table_setting"
    self.played_count.increment
    nofplayers = gets.chomp.to_i if nofplayers == nil
    game = self.games.create
    game.button = 1
    game.minimum_bet_amount = 2
    user_names.each_with_index do |u_name, idx|
      amount = 50
      seat = self.seats.find_or_create_by(seat_num: idx+1)
      user = User.where(user_id: u_name).first
      User.where(seat_id: seat.id).update_all(seat_id: nil)
      user.game = game
      user.amount = amount
      user.seat = seat
      user.save
    end
  end

  def is_table_finish
    p "is_table_finish start"
    stack = []
    @users = self.playing_users.map do |u|
      user = User.where(user_id: u).first
      stack << user.amount.to_i
      u
    end
    p "is_table_finish end"
    stack.include?(0) ? true : false
  end

  def table_finish
    results = []
    @users.each do |user|
      user.amount.to_i == 0 ? results << "lose" : results << "win"
    end
    @users.each do |user|
      user.stream({action: "show_result", result: results})
    end
    self.playing_users.clear
    self.seating_users.clear
  end

  def next_table_setting
    p "決着がついたっぽい"
  end
end
