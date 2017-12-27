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
  value :temp_pot
  value :bet_num
  value :current_bet_amount
  value :facing_bet_amount

  

  #after_create_commit { UserBroadcastJob.perform_later self }



  def push_info(string)
    users.each do |user|
      user.stream({action: "info", info: string})
    end
  end
  # def get_active_players
    
  # end
  # def get_turn_player
    
  # end
  # def get_button_player
    
  # end

  def start
    p "GAME START!!!!!!!!!!!!!!!!!"
    self.initial_game_setting
    self.preflop_setting
    return table.table_finish if table.is_table_finish
    user = Seat.where(table_id: self.table.id, seat_num: self.current_player).first.user
    if alives.include?(user.user_id) && actives.include?(user.user_id)
      self.urge_action_to_web(nil, self.bet_num.to_i, self.current_bet_amount.to_i, user.amount.to_i, user.prev_bet_num.to_i)
    end
  end

  def finish
    self.end_the_game
    sleep(2)
    p "GAME END!!!!!!!!!!!!!!!!!"
    self.start
  end

  def action
    c_user = Seat.where(table_id: self.table.id, seat_num: self.current_player).first.user
    return finish if is_finish
    if self.can_next_street == "true"
      calc_pot_from_betting_status
      postflop_setting
    end
    if alives.include?(c_user.user_id) && actives.include?(c_user.user_id)
      urge_action_to_web(nil, self.bet_num.to_i, self.current_bet_amount.to_i, c_user.amount.to_i, c_user.prev_bet_num.to_i)
    else
      check_next_street
      next_player
      action
    end
  end

  def urge_action_to_web(facing_bet = false, bet_num = 0, current_bet_amount, street_stack, your_prev_bet_num)
    p "urge_action_to_web start"
    c_user = Seat.where(table_id: self.table.id, seat_num: self.current_player).first.user
    facing_bet = self.facing_bet_amount.to_i > c_user.betting.to_i # true/false
    street_stack = c_user.amount.to_i
    users.each do |user|
      user.table.stream({action: "show_betting", id: user.seat.seat_num, betting: user.betting.to_i})
      user.table.stream({action: "show_stack", id: user.seat.seat_num, stack: user.amount.to_i})
    end
    if facing_bet
      if your_prev_bet_num == bet_num
        c_user.stream({action: "info", info:"you can do \'f\' or \'c\'"})
        c_user.stream({action: "urge_action", actions:["f","c"]})
      else
        if current_bet_amount >= street_stack
          c_user.stream({action: "info", info:"you can do \'f\' or \'c\'"})
          c_user.stream({action: "urge_action", actions:["f","c"]})
        else
          prev_bet_amount = self.prev_bet_amount.to_i
          min_raise = current_bet_amount * 2 - prev_bet_amount
          c_user.stream({action: "info", info:"you can do \'f\', \'c\' or \'r\'"})
          min_raise = street_stack if min_raise > street_stack
          c_user.stream({action: "urge_action", actions:["f","c","r"], raise_amounts: [min_raise,street_stack]})
        end
      end
    else
      minimum_bet_amount = self.minimum_bet_amount.to_i
      if bet_num == 0
        minimum_bet_amount = street_stack if minimum_bet_amount > street_stack
        c_user.stream({action: "info", info:"you can do \'x\' or \'b\'"})
        c_user.stream({action: "urge_action", actions:["x","b"], bet_amounts: [minimum_bet_amount,street_stack]})
      elsif bet_num == 1
        min_raise = minimum_bet_amount * 2
        min_raise = street_stack if min_raise > street_stack
        c_user.stream({action: "info", info:"you can do \'x\' or \'r\'"})
        c_user.stream({action: "urge_action", actions:["x","r"], raise_amounts: [min_raise,street_stack]})
      end
    end
    p "urge_action_to_web end"
  end

  def process_action(action_name, bet_amount)
    p "process_action start"
    c_user = Seat.where(table_id: self.table.id, seat_num: self.current_player).first.user
    bet_num = self.bet_num.to_i
    street_stack = c_user.amount.to_i
    facing_bet_amount = self.facing_bet_amount.to_i
    minimum_bet_amount = self.minimum_bet_amount.to_i
    current_bet_amount = self.current_bet_amount.to_i
    prev_bet_amount = self.prev_bet_amount.to_i
    min_raise = current_bet_amount * 2 - prev_bet_amount
    case action_name
    when "f"
      return [0,  0, nil]
    when "x"
      return [1, 0, bet_num]
    when "c"
      if street_stack <= facing_bet_amount
        return [5, street_stack, bet_num]
      else
        return [2, facing_bet_amount, bet_num]
      end
    when "b"
      if street_stack < minimum_bet_amount
        return [5, street_stack, bet_num]
      end
      if bet_amount == street_stack
        return [5, bet_amount, bet_num + 1]
      end
      return [3, bet_amount, bet_num + 1]
    when "r"
      min_raise = current_bet_amount * 2 - prev_bet_amount
      if min_raise == street_stack
        return [5, street_stack, bet_num + 1]
      elsif min_raise > street_stack
        return [5, street_stack, bet_num]
      else
        if bet_amount == street_stack
          return [5, bet_amount, bet_num + 1]
        end
        return [4, bet_amount, bet_num + 1]
      end
    else
      p "what an error!"
    end
    p "process_action end"
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
    # @game_users = table.playing_users.map do |u|
    table.playing_users.each do |u|
      user = User.where(user_id: u).first
      user.prev_bet_num = -1
      user.betting = 0
      user.rights_of_side_pot = 10
      if user.amount.to_i >= 0
        self.alives <<  u
        self.actives << u
      end
      # user
    end

    self.current_side_pot = 1
    self.side_pot_1 = self.side_pot_2 = self.side_pot_3 = self.side_pot_4 = self.side_pot_5 = self.side_pot_6 = self.side_pot_7 = self.side_pot_8 = self.side_pot_9 = 0
    self.current_player = nil
    p "initial_game_setting_end"
  end

  def is_finish
    p "is_game_finish? start"
    if alives.size == 1
      p "only one person is alive"
      return true
    end
    if self.street_num.to_i == 5
      p "go to showdown"
      return true
    end
    p "is_game_finish? end"
    false
  end
  
  def preflop_setting
    p "preflop_setting start"
    self.can_next_street = false
    self.prev_bet_amount = 0
    ####### pre flop 開始準備
    cards = JSON.parse(self.cards)
    users.each do |user|
      card = cards["player_#{user.seat.seat_num}"].join(",")
      user.hand = card
      user.stream({action: "deal_hand", cards: card})
    end
    ####### sbとbbの支払い
    #!!!ここでのAIに関して処理していない& 1Big等
    button_num = self.button.to_i
    table.stream({action: "deal_button", id: button_num})
    table.stream({action: "show_pot", pot: 0})
    unless users.size == 2
      if users.size < button_num + 1
        Seat.where(table_id: table.id, seat_num: 1).first.user.betting = 1
        Seat.where(table_id: table.id, seat_num: 2).first.user.betting = 2
      elsif users.size < button_num + 2
        Seat.where(table_id: table.id, seat_num: button_num+1).first.user.betting = 1
        Seat.where(table_id: table.id, seat_num: 1).first.user.betting = 2
      else
        Seat.where(table_id: table.id, seat_num: button_num+1).first.user.betting = 1
        Seat.where(table_id: table.id, seat_num: button_num+2).first.user.betting = 2
      end
      
      self.current_player = (button_num+3) % users.size
    else
      Seat.where(table_id: table.id, seat_num: button_num).first.user.betting = 1
      Seat.where(table_id: table.id, seat_num: button_num%2+1).first.user.betting = 2
      self.current_player = button_num
    end
    users.each do |user|
      table.stream({action: "show_betting", id: user.seat.seat_num, betting: user.betting.to_i})
      table.stream({action: "show_stack", id: user.seat.seat_num, stack: user.amount.to_i})
    end
    self.temp_pot = 3
    self.bet_num = 1
    self.current_bet_amount = 2
    self.facing_bet_amount = 2
    p "preflop_setting end"
  end

  def postflop_setting
    p "postflop_setting start"
    self.can_next_street = false
    self.prev_bet_amount = 0
    cards = JSON.parse(self.cards)
    case self.street_num.to_i
    when 2
      self.board = cards["flop"].join(",")
    when 3
      self.board += "," + (cards["turn"][0])
    when 4
      self.board += "," + (cards["river"][0])
    end
    table.stream({action: "deal_board", board: self.board.value})
    table.stream({action: "show_pot", pot: self.side_pot_1.to_i})#どのポットを見せるのが最適か？最後だけ？
    #buttonとアクションプレイヤーの設定
    self.current_player = self.button.to_i
    next_player

    self.bet_num = self.prev_bet_amount = self.current_bet_amount = self.facing_bet_amount = 0
    users.each_with_index do |user,idx|
      user.prev_bet_num = -1
      table.stream({action: "show_betting", id: idx+1, betting: user.betting})
      table.stream({action: "show_stack", id: idx+1, stack: user.amount})
    end
    p "postflop_setting end"
  end

  def calc_pot_from_betting_status
    p "calc_pot_from_betting_status start"
    # 前のストリートのpot処理
    if alives.size == actives.size || alives.size == 1 #全員AIしてない/AI入って、皆fold
      pot = eval("self.side_pot_" + self.current_side_pot).to_i + self.temp_pot.to_i
      eval("self.side_pot_" + self.current_side_pot + "= #{pot}")
      self.temp_pot = 0
    else #前のストリートで誰かがAI入れた時
      #誰が入れたのか
      street_alives = []
      allin_men = {}
      users.each_with_index do |user, idx|# 全ての人に実行
        if alives.include?(user.user_id)# foldしてない
          unless actives.include?(user.user_id)# AI済み or 最後の1人でAIを受けた
            betting = user.betting.to_i
            allin_men[idx+1] = betting if betting > 0
          end
          # サイドポット獲得権利が現在(前のストリート終了時)のサイドポット番号を上回っているなら
          street_alives << idx+1 if user.rights_of_side_pot.to_i > self.current_side_pot.to_i
        end
      end
      #入れた人の額を小さい順に並べる
      allin_men = allin_men.sort {|(k1, v1), (k2, v2)| v1 <=> v2 }
      #それ毎にサイドポットを作成する
      allin_men.each.with_index do |array, idx|
        current_side_pot = self.current_side_pot.to_i
        unless allin_men.size - (idx+1) <= 0 #4人オールインならば、3人目まで
          if allin_men[idx][1] == allin_men[idx+1][1] # n人目とn+1人目のオールイン額が一緒なら
            # n+1人目の権利を現在で確定
            Seat.where(table_id: table.id, seat_num: allin_men[idx+1][0]).first.user.rights_of_side_pot = self.current_side_pot
            # n人目の権利を現在で確定
            Seat.where(table_id: table.id, seat_num: array[0]).first.user.rights_of_side_pot = self.current_side_pot
          else # n人目とn+1人目のオールイン額が一緒でないなら
            # n人目の権利を現在で確定
            Seat.where(table_id: table.id, seat_num: array[0]).first.user.rights_of_side_pot = self.current_side_pot
            side_pot = 0 # サイドポットの金額計算
            allin_amount = 0
            users.each do |user|
              betting = user.betting.to_i
              if betting >= array[1]
                remain = betting - array[1]
                user.amount = user.amount.to_i - array[1]
                user.betting = remain
                side_pot += array[1]
              else
                user.amount = user.amount.to_i - user.betting.to_i
                user.betting = 0
                side_pot += betting
              end
              allin_amount = array[1]
            end
            allin_men.each do |array|
              array[1] -= allin_amount
            end
            self.temp_pot = self.temp_pot.to_i - side_pot
            side_pot += eval("self.side_pot_" + self.current_side_pot).to_i
            eval("self.side_pot_" + self.current_side_pot + "= #{side_pot}")# サイドポット金額確定
            (idx+1).times do |n|
              alives.delete(allin_men[n][0]) # 生存者から今回のAIをした人らを削除する
            end
            self.current_side_pot = self.current_side_pot.to_i + 1 # サイドポット番号を1進める
          end
        else #4人オールインならば、4人目
          # n人目の権利を現在で確定
          Seat.where(table_id: table.id, seat_num: array[0]).first.user.rights_of_side_pot = self.current_side_pot
          side_pot = self.temp_pot.to_i + eval("self.side_pot_" + self.current_side_pot).to_i # 残りpot
          eval("self.side_pot_" + self.current_side_pot + "= #{side_pot}") # サイドポット金額確定
          self.temp_pot = 0
          (idx+1).times do |n|
            alives.delete(allin_men[n][0]) # 生存者から今回のAIをした人らを削除する
          end
          self.current_side_pot = self.current_side_pot.to_i + 1 # サイドポット番号を1進める
        end
      end
    end
    users.each do |user|
      user.amount = user.amount.to_i - user.betting.to_i
      user.betting = 0
    end
    p "calc_pot_from_betting_status end"
  end

  def treat_action(array)
    p "treat_action start"
    result = [array[0].to_i, array[1].to_i, array[2].to_i]
    c_seat = Seat.where(table_id: self.table.id, seat_num: self.current_player).first
    c_user = c_seat.user
    if result[1] > 0
      pot = result[1] - c_user.betting.to_i + self.temp_pot.to_i
      self.temp_pot = pot
    end
    case result[0]
    when 0 #fold
      c_user.rights_of_side_pot = 0
      alives.delete(c_user.user_id)
      actives.delete(c_user.user_id)
      table.stream({action: "fold", id: c_seat.seat_num})
    when 1 #check
      # status["player_#{player}".to_sym][:betting] はそのまま
    when 2 #call
      c_user.betting = result[1]
      actives.clear if actives.size == 1
    when 3..4 #bet,raise
      self.prev_bet_amount = self.current_bet_amount
      self.current_bet_amount = result[1]
      self.facing_bet_amount = result[1]
      self.bet_num = self.bet_num.to_i + 1 unless result[2] == self.bet_num.to_i
      c_user.betting = result[1]
      actives.clear if actives.size == 1
    when 5 #all-in
      if result[2] == self.bet_num.to_i
        self.facing_bet_amount = result[1] if self.facing_bet_amount.to_i < result[1]
        c_user.betting = result[1]
      else
        self.bet_num = self.bet_num.to_i + 1
      end
      actives.delete(c_user.user_id)
      self.prev_bet_amount = self.current_bet_amount
      self.current_bet_amount = result[1]
      self.facing_bet_amount = result[1]
      c_user.betting = result[1]
    end
    c_user.prev_bet_num = result[2]
    p "treat_action end"
  end
  
  def next_player
    p "next_player start"
    self.current_player = self.current_player.to_i % users.size + 1
    p "next_player end"
  end

  def check_next_street
    p "check_next_street start"
    c_user = Seat.where(table_id: self.table.id, seat_num: self.current_player).first.user
    check_1 = actives.include?(c_user.user_id)
    p check_1
    check_2 = self.facing_bet_amount.to_i == c_user.betting.to_i
    p check_2
    check_3 = self.bet_num.to_i == c_user.prev_bet_num.to_i
    p check_3
    all_in_check = actives.size == 0
    p all_in_check
    if all_in_check || (check_1 && check_2 && check_3)
      self.can_next_street = true
      self.street_num = self.street_num.to_i + 1
      p "go to next street"
    end
    p "check_next_street end"
  end

  def end_the_game
    p "end_the_game start"
    calc_pot_from_betting_status
    winners = get_winner
    give_pot(winners)
    next_game_setting
    p "end_the_game end"
  end

  def get_winner
    p "get_winner start"
    sorted_winners = []
    if self.street_num.to_i == 5
      array_hands = []
      users.each_with_index do |user,idx|
        if alives.include?(user.user_id)
          hand = user.hand
          array_hands << hand.split(",")
          table.stream({action: "showdown_opp_hand", cards: hand.value, id: idx+1})
        else
          array_hands << []
        end
      end
      sorted_winners = Card.get_wh_at_showdown(self.board.split(","), array_hands)
      push_info("player_#{sorted_winners[0][3]} win by #{sorted_winners[0][1]} with #{sorted_winners[0][2]}")
    else
      alive = nil
      users.each_with_index do |user,idx|
        if alives.include?(user.user_id)
          alive = idx + 1
        end
      end
      sorted_winners = [[nil,nil,nil,alive]]
      push_info("player_#{sorted_winners[0][3]} win by #{sorted_winners[0][1]} with #{sorted_winners[0][2]}")
    end
    p "get_winner end"
    sorted_winners
  end

  def give_pot(winners)
    rights = users.map do |user|# [1, 2, 2, 0]
      user.rights_of_side_pot.to_i
    end
    
    9.times do |n|
      if eval("self.side_pot_" + self.current_side_pot).to_i > 0
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
          pot = eval("self.side_pot_" + self.current_side_pot).to_i / gifted_player.size
          remain = eval("self.side_pot_" + self.current_side_pot).to_i % gifted_player.size
          button = self.button.to_i
          position = gifted_player.map {|pr| pr + button}
          bad_position = position.sort[0] - button
          push_info("player#{gifted_player} win by side_pot_#{n+1}($#{pot})")
          gifted_player.each do |got_player|
            user = Seat.where(table_id: table.id, seat_num: got_player).first.user
            amount = user.amount.to_i
            if got_player == bad_position
              user.amount = amount + pot + remain
            else
              user.amount = amount + pot
            end
          end
        end
      end
    end
  end

  def next_game_setting
    table.played_count.increment
    self.button = self.button.to_i % users.size + 1
    p "1 game finished. go to next game"
  end
end
