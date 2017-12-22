class Table
  #after_create_commit { UserBroadcastJob.perform_later self }
  # attr_accessor :title, :price

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
  def initial_table_setting(nofplayers = nil, *user_names)
    p "initial_table_setting"
    redis.hset(:game, :number, 1)
    nofplayers = gets.chomp.to_i if nofplayers == nil
    redis.hmset(:game, :nofpeople, nofplayers, :button, 1, :minimum_bet_amount, 2, :nofalive, nofplayers)
    nofplayers.times do |n|
      # puts "how much player_#{n+1} has?"
      # amount = gets.chomp.to_i
      amount = 50
      redis.hmset(player(n+1), :name, user_names[n], :amount, amount)
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
