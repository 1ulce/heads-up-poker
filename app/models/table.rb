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


  def redis
    @redis ||= Redis.current
  end

  def push_info(string)
    p string
    redis.llen("playing_users").times do |n| 
      user = redis.lindex("playing_users", n)
      ActionCable.server.broadcast "user_#{user}", {action: "info", info: string}
    end
  end

  def max
    2
  end

  def stream(data, to = "room_#{self.id}")
    raise if self.id != 1
    ActionCable.server.broadcast to, data
  end
  def name
  end
  def game_type 
     
  end
  def sit
    
  end
  def watch
    
  end
  def status
  end
  def get_sitting_users
    
  end
  def get_sitting_user()
    
  end
  def player(int)
    "player_#{int}".to_sym
  end

  def get_player_num(player_name)
    9.times do |n|
      u_name = redis.hget("player_#{n+1}".to_sym, :name)
      if player_name == u_name
        return n+1
      end
      n + 1
    end
    raise
  end
  def get_player_name(int)
    redis.hget(player(int), :name)
  end
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
      user.amount = amount
      user.seat = seat
      user.save
    end
  end
  def is_table_finish
    p "is_table_finish?"
    stack = []
    redis.hget(:game, :nofpeople).to_i.times do |n|
      stack << redis.hget(player(n+1), :amount).to_i
    end
    stack.include?(0) ? true : false
  end
  def table_finish
    results = []
    2.times do |n|
      if redis.hget(self.player(n+1), :amount).to_i == 0
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
  def next_table_setting
    p "決着がついたっぽい"
  end
end
