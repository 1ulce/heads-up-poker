class Game < ApplicationRecord
  include Redis::Objects
  has_many :users
  belongs_to :table, optional: true
  value :cards
  value :street_num
  value :board
  set :alives
  set :actives
  value :current_side_pot
  value :side_pot_1
  value :side_pot_2
  value :side_pot_3
  value :side_pot_4
  value :side_pot_5
  value :side_pot_6
  value :side_pot_7
  value :side_pot_8
  value :side_pot_9
  value :current_player
  value :can_next_street
  value :prev_bet_amount
  value :button
  value :minimum_bet_amount

  #after_create_commit { UserBroadcastJob.perform_later self }
  def redis
    @redis ||= Redis.current
  end

  # def table
  #   @table ||= self.table
  # end

  def push_info(string)
    table.playing_users.each do |u_name|
      ActionCable.server.broadcast "user_#{u_name}", {action: "info", info: string}
    end
  end
  def get_active_players
    
  end
  def get_turn_player
    
  end
  def get_button_player
    
  end
  def start
    p "GAME START!!!!!!!!!!!!!!!!!"
    self.initial_game_setting
    self.preflop_setting
    return table.table_finish if table.is_table_finish
    current_player = redis.hget(:game, :current_player).to_i
    if redis.hget(table.player(current_player), :alive) == "true" && redis.hget(table.player(current_player), :active) == "true"
      self.urge_action_to_web(nil, redis.hget(:street, :nofbet).to_i, redis.hget(:game, :current_bet_amount).to_i, redis.hget(table.player(current_player), :amount).to_i, redis.hget(table.player(current_player), :prev_nofbet).to_i)
    end
  end
  def finish
    self.end_the_game
    sleep(2)
    p "GAME END!!!!!!!!!!!!!!!!!"
    self.start
  end

  def action
    unless redis.hget(:street, :can_next_street) == "true"
      return self.finish if self.is_finish
      current_player = redis.hget(:game, :current_player).to_i
      if redis.hget(table.player(current_player), :alive) == "true" && redis.hget(table.player(current_player), :active) == "true"
        self.urge_action_to_web(nil, redis.hget(:street, :nofbet).to_i, redis.hget(:game, :current_bet_amount).to_i, redis.hget(table.player(current_player), :amount).to_i, redis.hget(table.player(current_player), :prev_nofbet).to_i)
      else
        self.check_next_street
        self.next_player
        action
      end
    else
      return self.finish if self.is_finish
      self.calc_pot_from_betting_status
      self.postflop_setting
      current_player = redis.hget(:game, :current_player).to_i
      if redis.hget(table.player(current_player), :alive) == "true" && redis.hget(table.player(current_player), :active) == "true"
        self.urge_action_to_web(nil, redis.hget(:street, :nofbet).to_i, redis.hget(:game, :current_bet_amount).to_i, redis.hget(table.player(current_player), :amount).to_i, redis.hget(table.player(current_player), :prev_nofbet).to_i)
      else
        self.check_next_street
        self.next_player
        self.action
      end
    end
  end
  def urge_action_to_web(facing_bet = false, nofbet = 0, current_bet_amount, street_stack, your_prev_nofbet)
    p "urge_action_to_web"
    current_player = redis.hget(:game, :current_player).to_i
    facing_bet = redis.hget(:game, :facing_bet_amount).to_i > redis.hget(table.player(current_player), :betting).to_i || false
    u_name = table.get_player_name(redis.hget(:game, :current_player).to_i)
    street_stack = redis.hget(table.player(current_player), :amount).to_i
    redis.hget(:game, :nofpeople).to_i.times do |n|
      ActionCable.server.broadcast "room_1", {action: "show_betting", id: n+1, betting: redis.hget(table.player(n+1),:betting)}
      ActionCable.server.broadcast "room_1", {action: "show_stack", id: n+1, stack: redis.hget(table.player(n+1),:amount)}
    end
    if facing_bet
      if your_prev_nofbet == nofbet
        ActionCable.server.broadcast "user_#{u_name}", {action: "info", info:"you can do \'f\' or \'c\'"}
        ActionCable.server.broadcast "user_#{u_name}", {action: "urge_action", actions:["f","c"]}
      else
        if current_bet_amount >= street_stack
          ActionCable.server.broadcast "user_#{u_name}", {action: "info", info:"you can do \'f\' or \'c\'"}
          ActionCable.server.broadcast "user_#{u_name}", {action: "urge_action", actions:["f","c"]}
        else
          current_bet_amount = redis.hget(:game, :current_bet_amount).to_i
          prev_bet_amount = redis.hget(:game, :prev_bet_amount).to_i
          min_raise = current_bet_amount * 2 - prev_bet_amount
          ActionCable.server.broadcast "user_#{u_name}", {action: "info", info:"you can do \'f\', \'c\' or \'r\'"}
          min_raise = street_stack if min_raise > street_stack
          ActionCable.server.broadcast "user_#{u_name}", {action: "urge_action", actions:["f","c","r"], raise_amounts: [min_raise,street_stack]}
        end
      end
    else
      minimum_bet_amount = redis.hget(:game, :minimum_bet_amount).to_i
      if nofbet == 0
        minimum_bet_amount = street_stack if minimum_bet_amount > street_stack
        ActionCable.server.broadcast "user_#{u_name}", {action: "info", info:"you can do \'x\' or \'b\'"}
        ActionCable.server.broadcast "user_#{u_name}", {action: "urge_action", actions:["x","b"], bet_amounts: [minimum_bet_amount,street_stack]}
      elsif nofbet == 1
        min_raise = minimum_bet_amount * 2
        min_raise = street_stack if min_raise > street_stack
        ActionCable.server.broadcast "user_#{u_name}", {action: "info", info:"you can do \'x\' or \'r\'"}
        ActionCable.server.broadcast "user_#{u_name}", {action: "urge_action", actions:["x","r"], raise_amounts: [min_raise,street_stack]}
      end
    end
  end

  def process_action(action_name, bet_amount)
    p "process_action"
    current_player = redis.hget(:game, :current_player).to_i
    nofbet = redis.hget(:street, :nofbet).to_i
    street_stack = redis.hget(table.player(self.current_player.to_i), :amount).to_i
    facing_bet_amount = redis.hget(:game, :facing_bet_amount).to_i
    minimum_bet_amount = redis.hget(:game, :minimum_bet_amount).to_i
    current_bet_amount = redis.hget(:game, :current_bet_amount).to_i
    prev_bet_amount = redis.hget(:game, :prev_bet_amount).to_i
    min_raise = current_bet_amount * 2 - prev_bet_amount
    case action_name
    when "f"
      return [0, 0, nil]
    when "x"
      return [1, 0, nofbet]
    when "c"
      if street_stack <= facing_bet_amount
        return [5, street_stack, nofbet]
      else
        return [2, facing_bet_amount, nofbet]
      end
    when "b"
      if street_stack < minimum_bet_amount
        return [5, street_stack, nofbet]
      end
      if bet_amount == street_stack
        return [5, bet_amount, nofbet + 1]
      end
      return [3, bet_amount, nofbet + 1]
    when "r"
      min_raise = current_bet_amount * 2 - prev_bet_amount
      if min_raise == street_stack
        return [5, street_stack, nofbet + 1]
      elsif min_raise > street_stack
        return [5, street_stack, nofbet]
      else
        if bet_amount == street_stack
          return [5, bet_amount, nofbet + 1]
        end
        return [4, bet_amount, nofbet + 1]
      end
    else
      p "what an error!"
    end
  end
  def initial_game_setting
    p "initial_game_setting_start"
    deck = Card.get_shuffled_card
    cards = {
      player_1: [deck[0],deck[1]],
      player_2: [deck[2],deck[3]],
      player_3: [deck[4],deck[5]],
      player_4: [deck[6],deck[7]],
      player_5: [deck[8],deck[9]],
      player_6: [deck[10],deck[11]],
      player_7: [deck[12],deck[13]],
      player_8: [deck[14],deck[15]],
      player_9: [deck[16],deck[17]],
      player_10: [deck[18],deck[19]],
      board: [deck[20],deck[21],deck[22],deck[23],deck[24]],
      flop: [deck[20],deck[21],deck[22]],
      turn: [deck[23]],
      river: [deck[24]],
      rit_board: [deck[25],deck[26],deck[27],deck[28],deck[29]],
      rit_flop: [deck[25],deck[26],deck[27]],
      rit_turn: [deck[28]],
      rit_river: [deck[29]],
    }
    self.cards = cards.to_json
    self.street_num = 1
    self.board = ""
    self.alives.clear
    self.actives.clear
    @users = table.playing_users.map do |u|
      user = User.where(user_id: u).first
      user.prev_bet_num = nil
      user.betting = 0
      user.rights_of_side_pot = 10
      if user.amount.to_i >= 0
        self.alives <<  u
        self.actives << u
      end
      user
    end
    self.current_side_pot = 1
    self.side_pot_1 = self.side_pot_2 = self.side_pot_3 = self.side_pot_4 = self.side_pot_5 = self.side_pot_6 = self.side_pot_7 = self.side_pot_8 = self.side_pot_9 = 0
    self.current_player = nil
    p "initial_game_setting_end"
  end
  def is_finish
    p "is_game_finish?"
    if redis.hget(:game, :nofalive).to_i == 1
      puts "only one person is alive"
      return true
    end
    if redis.hget(:street, :nofstreet).to_i == 5
      puts "go to showdown"
      return true
    end
    false
  end
  def preflop_setting
    p "preflop_setting"
    self.can_next_street = false
    self.prev_bet_amount = 0
    ####### pre flop 開始準備
    cards = JSON.parse(self.cards)
    @users.each do |user|
      card = cards["player_#{user.seat.seat_num}"].join(",")
      user.hand = card
      user.stream({action: "deal_hand", cards: card})
    end
    ######################################ここまでリファクタリング済み
    ####### sbとbbの支払い
    #!!!ここでのAIに関して処理していない& 1Big等
    button_num = redis.hget(:game, :button).to_i
    ActionCable.server.broadcast "room_1", {action: "deal_button", id: button_num}
    ActionCable.server.broadcast "room_1", {action: "show_pot", pot: 0}
    unless redis.hget(:game, :nofpeople).to_i == 2
      if redis.hget(:game, :nofpeople).to_i < button_num + 1
        redis.hset(:player_1, :betting, 1)
        redis.hset(:player_2, :betting, 2)
      elsif redis.hget(:game, :nofpeople).to_i < button_num + 2
        redis.hset(table.player(button_num+1), :betting, 1)
        redis.hset(:player_1, :betting, 2)
      else
        redis.hset(table.player(button_num+1), :betting, 1)
        redis.hset(table.player(button_num+2), :betting, 2)
      end
      
      current_player = button_num

      3.times do 
        if redis.hget(:game, :nofpeople).to_i == current_player
          current_player = 1
        else
          current_player += 1
        end
      end
    else
      if button_num == 1
        redis.hset(table.player(1), :betting, 1)
        redis.hset(table.player(2), :betting, 2)
        current_player = 1
      else
        redis.hset(table.player(2), :betting, 1)
        redis.hset(table.player(1), :betting, 2)
        current_player = 2
      end
    end
    redis.hget(:game, :nofpeople).to_i.times do |n|
      ActionCable.server.broadcast "room_1", {action: "show_betting", id: n+1, betting: redis.hget(table.player(n+1),:betting)}
      ActionCable.server.broadcast "room_1", {action: "show_stack", id: n+1, stack: redis.hget(table.player(n+1),:amount)}
    end
    redis.hset(:game ,:current_player, current_player)
    redis.hset(:street ,:temp_pot, 3)
    redis.hset(:street, :nofbet, 1)
    redis.hset(:game, :current_bet_amount, 2)
    redis.hset(:game, :facing_bet_amount, 2)
  end
  def postflop_setting
    p "postflop_setting"
    redis.hset(:street, :can_next_street, false)
    redis.hset(:game, :prev_bet_amount, 0)
    cards = cards = JSON.parse(redis.hget(:game, :cards))
    case redis.hget(:street, :nofstreet).to_i
    when 2
      redis.hset(:game, :board, cards["flop"].join(","))
    when 3
      new_board = redis.hget(:game, :board) + "," + (cards["turn"][0])
      redis.hset(:game, :board, new_board)
    when 4
      new_board = redis.hget(:game, :board) + "," + (cards["river"][0])
      redis.hset(:game, :board, new_board)
    end
    ActionCable.server.broadcast "room_1", {action: "deal_board", board: redis.hget(:game, :board)}
    ActionCable.server.broadcast "room_1", {action: "show_pot", pot: redis.hget(:game, :side_pot_1)}
    #buttonとアクションプレイヤーの設定
    current_player = redis.hget(:game, :button).to_i
    if redis.hget(:game, :nofpeople).to_i == current_player
      current_player = 1
    else
      current_player += 1
    end
    redis.hset(:street, :nofbet, 0)
    redis.hmset(:game, :prev_bet_amount, 0, :current_bet_amount, 0, :facing_bet_amount, 0, :current_player, current_player)
    redis.hget(:game, :nofpeople).to_i.times do |n|
      redis.hset(table.player(n+1), :prev_nofbet, nil)
      ActionCable.server.broadcast "room_1", {action: "show_betting", id: n+1, betting: redis.hget(table.player(n+1),:betting)}
      ActionCable.server.broadcast "room_1", {action: "show_stack", id: n+1, stack: redis.hget(table.player(n+1),:amount)}
    end
  end
  def calc_pot_from_betting_status
    p "calc_pot_from_betting_status"
    # 前のストリートのpot処理
    nof_alive = redis.hget(:game, :nofalive).to_i
    nof_active = redis.hget(:game, :nofactive).to_i
    nofside_pot = redis.hget(:game, :nofside_pot).to_i
    if nof_alive == nof_active || nof_alive == 1 #全員AIしてない/AI入って、皆fold
      pot = redis.hget(:game, "side_pot_#{nofside_pot}".to_sym).to_i + redis.hget(:street, :temp_pot).to_i
      redis.hset(:game, "side_pot_#{nofside_pot}".to_sym, pot)
      redis.hset(:street, :temp_pot, 0)
    else #前のストリートで誰かがAI入れた時
      #誰が入れたのか
      alives = []
      allin_men = {}
      redis.hget(:game, :nofpeople).to_i.times do |n| # 全ての人に実行
        if redis.hget(table.player(n+1), :alive) == "true" # foldしてない
          if redis.hget(table.player(n+1), :active) == "false" # AI済み or 最後の1人でAIを受けた
            betting = redis.hget(table.player(n+1), :betting).to_i
            if betting > 0
              allin_men[n+1] = redis.hget(table.player(n+1), :betting).to_i # AI勝負人に名と金額を連ねる
            end
          end
          # サイドポット獲得権利が現在(前のストリート終了時)のサイドポット番号を上回っているなら
          if redis.hget(table.player(n+1), :rights_of_side_pot).to_i > redis.hget(:game, :nofside_pot).to_i
            alives << n+1 # 生存者として名を連ねる
          end
        end
      end
      #入れた人の額を小さい順に並べる
      allin_men = allin_men.sort {|(k1, v1), (k2, v2)| v1 <=> v2 }
      #それ毎にサイドポットを作成する
      allin_men.each.with_index do |array, idx|
        nofside_pot = redis.hget(:game, :nofside_pot).to_i
        unless allin_men.count - (idx + 1) <= 0 #4人オールインならば、3人目まで
          if allin_men[idx][1] == allin_men[idx+1][1] # n人目とn+1人目のオールイン額が一緒なら
            redis.hset(table.player(allin_men[idx+1][0]), :rights_of_side_pot, nofside_pot) # n+1人目の権利を現在で確定
            redis.hset(table.player(array[0]), :rights_of_side_pot, nofside_pot) # n人目の権利を現在で確定
          else # n人目とn+1人目のオールイン額が一緒でないなら
            redis.hset(table.player(array[0]), :rights_of_side_pot, nofside_pot) # n人目の権利を現在で確定
            
            side_pot = 0 # サイドポットの金額計算
            allin_amount = 0
            redis.hget(:game, :nofpeople).to_i.times do |n|
              betting = redis.hget(table.player(n+1), :betting).to_i
              if betting >= array[1]
                remain = betting - array[1]
                amount = redis.hget(table.player(n+1), :amount).to_i - array[1]
                redis.hset(table.player(n+1), :amount, amount)
                redis.hset(table.player(n+1), :betting, remain)
                side_pot += array[1]
              else
                amount = redis.hget(table.player(n+1), :amount).to_i - redis.hget(table.player(n+1), :betting).to_i
                redis.hset(table.player(n+1), :amount, amount)
                redis.hset(table.player(n+1), :betting, 0)
                side_pot += betting
              end
              allin_amount = array[1]
            end
            allin_men.each do |array|
              array[1] -= allin_amount
            end
            temp_pot = redis.hget(:street, :temp_pot).to_i - side_pot
            redis.hset(:street, :temp_pot, temp_pot)
            side_pot = side_pot + redis.hget(:game, "side_pot_#{nofside_pot}".to_sym).to_i
            redis.hset(:game, "side_pot_#{nofside_pot}".to_sym, side_pot) # サイドポット金額確定
            (idx+1).times do |n|
              alives.delete(allin_men[n][0]) # 生存者から今回のAIをした人らを削除する
            end
            redis.hset(:game, :nofside_pot, nofside_pot + 1) # サイドポット番号を1進める
          end
        else #4人オールインならば、4人目
          redis.hset(table.player(array[0]), :rights_of_side_pot, nofside_pot) # n人目の権利を現在で確定
          side_pot = redis.hget(:street, :temp_pot).to_i + redis.hget(:game, "side_pot_#{nofside_pot}".to_sym).to_i # 残りpot
          redis.hset(:street, :temp_pot, 0)
          redis.hset(:game, "side_pot_#{nofside_pot}".to_sym, side_pot) # サイドポット金額確定
          (idx+1).times do |n|
            alives.delete(allin_men[n][0]) # 生存者から今回のAIをした人らを削除する
          end
          redis.hset(:game, :nofside_pot, nofside_pot + 1) # サイドポット番号を1進める
        end
      end
    end
    redis.hget(:game, :nofpeople).to_i.times do |n|
      amount = redis.hget(table.player(n+1), :amount).to_i - redis.hget(table.player(n+1), :betting).to_i
      redis.hset(table.player(n+1), :amount, amount)
      redis.hset(table.player(n+1), :betting, 0)
    end
  end
  def treat_action(array)
    puts "treat_action"
    result = [array[0].to_i, array[1].to_i, array[2].to_i]
    current_player = redis.hget(:game, :current_player).to_i
    if result[1] > 0
      pot = (result[1] - redis.hget(table.player(current_player), :betting).to_i) + redis.hget(:street, :temp_pot).to_i
      redis.hset(:street, :temp_pot, pot)
    end
    case result[0]
    when 0
      redis.hset(table.player(current_player), :rights_of_side_pot, 0)
      redis.hset(table.player(current_player), :active, false)
      nofactive = redis.hget(:game, :nofactive).to_i - 1
      redis.hset(:game, :nofactive, nofactive)

      redis.hset(table.player(current_player), :alive, false)
      nofalive = redis.hget(:game, :nofalive).to_i - 1
      redis.hset(:game, :nofalive, nofalive)
      ActionCable.server.broadcast "room_1", {action: "fold", id: current_player}
    when 1
      # status["player_#{player}".to_sym][:betting] はそのまま
    when 2
      redis.hset(table.player(current_player), :betting, result[1])
      
      nofactive = redis.hget(:game, :nofactive).to_i
      if nofactive == 1
        redis.hset(table.player(current_player), :active, false)
        redis.hset(:game, :nofactive, nofactive - 1)
      end
    when 3..4
      redis.hset(:game, :prev_bet_amount, redis.hget(:game, :current_bet_amount))
      redis.hset(:game, :current_bet_amount, result[1])
      redis.hset(:game, :facing_bet_amount, result[1])
      unless result[2] == redis.hget(:street, :nofbet).to_i
        nofbet = redis.hget(:street, :nofbet).to_i + 1
        redis.hset(:street, :nofbet, nofbet)
      end
      redis.hset(table.player(current_player), :betting, result[1])

      nofactive = redis.hget(:game, :nofactive).to_i
      if nofactive == 1
        redis.hset(table.player(current_player), :active, false)
        redis.hset(:game, :nofactive, nofactive - 1)
      end
    when 5
      if result[2] == redis.hget(:street, :nofbet).to_i
        # prev_bet_amountはこのまま
        # current_bet_amountはこのまま
        if redis.hget(:game, :facing_bet_amount).to_i < result[1]
          redis.hset(:game, :facing_bet_amount, result[1])
        end
        # nofbetはこのまま
        redis.hset(table.player(current_player), :betting, result[1])
      else
        nofbet = redis.hget(:street, :nofbet).to_i + 1
        redis.hset(:street, :nofbet, nofbet)
      end
      redis.hset(table.player(current_player), :active, false)
      nofactive = redis.hget(:game, :nofactive).to_i - 1
      redis.hset(:game, :nofactive, nofactive)

      redis.hset(:game, :prev_bet_amount, redis.hget(:game, :current_bet_amount))
      redis.hset(:game, :current_bet_amount, result[1])
      redis.hset(:game, :facing_bet_amount, result[1])
      redis.hset(table.player(current_player), :betting, result[1])
    end
    redis.hset(table.player(current_player), :prev_nofbet, result[2])
  end
  def next_player
    p "next_player"
    current_player = redis.hget(:game, :current_player).to_i
    if redis.hget(:game, :nofpeople).to_i == current_player
      current_player = 1
    else
      current_player += 1
    end
      redis.hset(:game, :current_player, current_player)
  end
  def check_next_street
    puts "check_next_street"
    current_player = redis.hget(:game, :current_player)
    check_1, check_2, check_3, check_4 = false, false, false, false
    puts "check_1"
    p check_1 = true if redis.hget(table.player(current_player), :active) == "true"
    puts "check_2"
    p check_2 = true if redis.hget(:game, :facing_bet_amount) == redis.hget(table.player(current_player), :betting)
    puts "check_3"
    p check_3 = true if redis.hget(:street, :nofbet) == redis.hget(table.player(current_player), :prev_nofbet)
    puts "check_4"
    p check_4 = true if redis.hget(:game, :nofactive).to_i == 0
    if check_4
      redis.hset(:street, :can_next_street, true)
      nofstreet = redis.hget(:street, :nofstreet).to_i + 1
      redis.hset(:street, :nofstreet, nofstreet)
      puts "!!!!!Game!!!!!"
      puts redis.hscan("game",0)
      puts "!!!!!Street!!!!!"
      puts redis.hscan("street",0)
      redis.hget(:game, :nofpeople).to_i.times do |n|
        puts "!!!!!Player_#{n+1}!!!!!"
        puts redis.hscan(table.player(n+1),0)
      end
      puts "ALLIN appears and nothing to change. go to next street"
    elsif check_1 && check_2 && check_3
      redis.hset(:street, :can_next_street, true)
      nofstreet = redis.hget(:street, :nofstreet).to_i + 1
      redis.hset(:street, :nofstreet, nofstreet)
      puts "go to next street"
      puts "!!!!!Game!!!!!"
      puts redis.hscan("game",0)
      puts "!!!!!Street!!!!!"
      puts redis.hscan("street",0)
      redis.hget(:game, :nofpeople).to_i.times do |n|
        puts "!!!!!Player_#{n+1}!!!!!"
        puts redis.hscan(table.player(n+1),0)
      end
    end
  end
  def end_the_game
    p "end_the_game"
    calc_pot_from_betting_status
    winners = get_winner
    give_pot(winners)
    next_game_setting
    # initial_game_setting
  end
  def get_winner
    sorted_winners = []
    if redis.hget(:street, :nofstreet).to_i == 5
      array_hands = []
      redis.hget(:game, :nofpeople).to_i.times do |n|
        if redis.hget(table.player(n+1), :alive) == "true"
          hand = redis.hget(table.player(n+1), :hand)
          array_hands << hand.split(",")
          ActionCable.server.broadcast "room_1", {action: "showdown_opp_hand", cards: hand, id: n+1}
        else
          array_hands << []
        end
      end
      sorted_winners = card.get_wh_at_showdown(redis.hget(:game, :board).split(","), array_hands)
      push_info("player_#{sorted_winners[0][3]} win by #{sorted_winners[0][1]} with #{sorted_winners[0][2]}")
    else
      alive = nil
      redis.hget(:game, :nofpeople).to_i.times do |n|
        if redis.hget(table.player(n+1), :alive) == "true"
          alive = n + 1
        end
      end
      sorted_winners = [[nil,nil,nil,alive]]
      push_info("player_#{sorted_winners[0][3]} win by #{sorted_winners[0][1]} with #{sorted_winners[0][2]}")
    end
    sorted_winners
  end
  def give_pot(winners)
    rights = redis.hget(:game, :nofpeople).to_i.times.map do |n| # [1, 2, 2, 0]
      redis.hget(table.player(n+1), :rights_of_side_pot).to_i
    end

    9.times do |n|
      if redis.hget(:game, "side_pot_#{n+1}".to_sym).to_i > 0
        rights_players = []
        give = false
        gifted_player = []
        prev_result = [nil,nil,nil,nil]
        rights.each.with_index do |int,idx| 
          if int >= n+1 #pot獲得権があれば
            rights_players << idx+1 #[1,2,3]
          end
        end

        winners.each do |result|
          if result[0] == prev_result[0] && result[2] == prev_result[2] #前回のと役とキッカーが一緒ならば
          else 
            if gifted_player.count > 0 #一緒でなく、potを上げる人がいるならば
              break
            end
          end
          prev_result = result

          rights_players.each do |prayer|
            if result[3] == prayer
              give = true
              gifted_player << prayer
            end
          end
        end

        if give == true
          pot = redis.hget(:game, "side_pot_#{n+1}".to_sym).to_i / gifted_player.count 
          remain = redis.hget(:game, "side_pot_#{n+1}".to_sym).to_i % gifted_player.count
          button = redis.hget(:game, :button).to_i
          position = gifted_player.map {|p| p + button}
          bad_position = position.sort[0] - button
          push_info("player#{gifted_player} win by side_pot_#{n+1}($#{pot})")
          gifted_player.each do |got_player|
            amount = redis.hget(table.player(got_player), :amount).to_i
            if got_player == bad_position
              redis.hset(table.player(got_player), :amount, amount + pot + remain)
            else
              redis.hset(table.player(got_player), :amount, amount + pot)
            end
          end
        end
      end
    end
  end
  def next_game_setting
    number = redis.hget(:game, :number).to_i + 1
    redis.hset(:game, :number, number)
    button_player = redis.hget(:game, :button).to_i
    if redis.hget(:game, :nofpeople).to_i == button_player
      button_player = 1
    else
      button_player += 1
    end
    redis.hset(:game, :button, button_player)
    p "1 game finished. go to next game"
  end
end
