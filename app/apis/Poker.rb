class Poker
  TRUMP = ["As","2s","3s","4s","5s","6s","7s","8s","9s","Ts","Js","Qs","Ks","Ah","2h","3h","4h","5h","6h","7h","8h","9h","Th","Jh","Qh","Kh","Ad","2d","3d","4d","5d","6d","7d","8d","9d","Td","Jd","Qd","Kd","Ac","2c","3c","4c","5c","6c","7c","8c","9c","Tc","Jc","Qc","Kc"]
  class << self
    
    def redis
      @redis ||= Redis.current
    end

    def get_handRank(array) #例 ["Ac","As","Ts","9h","9h","9s","2d"] 返り値 [7, "fullhouse", [9, 14]]
      is_flush = false
      is_straight = false
      judge = {s: [0,[]],h: [0,[]],d: [0,[]],c: [0,[]]}
      complete_flush_nums = []
      num_hands = []

      array.each do |hand| 
        n_hand = convert_hand_to_num(hand[0])
        judge[hand[-1].to_sym][0] += 1
        judge[hand[-1].to_sym][1] << n_hand
        num_hands << n_hand
      end
      
      judge.keys.each do |sym|
        if judge[sym][0] > 4
          is_flush = true
          judge[sym][1].sort! {|a, b| b <=> a }
          flag, complete_straight_nums = is_straight(judge[sym][1])
          if flag
            complete_nums = complete_straight_nums
            return [9, "straight flush", complete_nums]
          end
          complete_flush_nums = judge[sym][1].take(5)
        end
      end
      
      is_straight, complete_straight_nums = is_straight(num_hands)
      four_card = num_hands.inject(Hash.new(0)){|h, i| h[i] += 1; h }.reject{|k, v| v <= 3 }.keys
      three_card = num_hands.inject(Hash.new(0)){|h, i| h[i] += 1; h }.reject{|k, v| v <= 2 }.keys.sort {|a, b| b <=> a }
      pair = num_hands.inject(Hash.new(0)){|h, i| h[i] += 1; h }.reject{|k, v| v <= 1 }.keys.sort {|a, b| b <=> a }
      high_cards = num_hands.sort {|a, b| b <=> a }
      
      if four_card.count == 1
        high_cards.delete(four_card[0])
        complete_nums = [four_card[0],high_cards[0]]
        return [8, "four of a kind", complete_nums]
      end
      if three_card.count > 0 && pair.count > 1
        pair.delete(three_card[0])
        complete_nums = [three_card[0],pair[0]]
        return [7, "fullhouse", complete_nums]
      end
      if is_flush
        complete_nums = complete_flush_nums
        return [6, "flush", complete_nums]
      end
      if is_straight
        complete_nums = complete_straight_nums
        return [5, "straight", complete_nums]
      end
      if three_card.count == 1
        high_cards.delete(three_card[0])
        complete_nums = [three_card[0],high_cards[0],high_cards[1]]
        return [4, "three of a kind", complete_nums]
      end
      if pair.count > 1
        high_cards.delete(pair[0])
        high_cards.delete(pair[1])
        complete_nums = [pair[0],pair[1],high_cards[0]]
        return [3, "two pair", complete_nums]
      end
      if pair.count == 1
        high_cards.delete(pair[0])
        complete_nums = [pair[0],high_cards[0],high_cards[1],high_cards[2]]
        return [2, "one pair", complete_nums]
      end
      complete_nums = high_cards.take(5)
      return [1, "high card", complete_nums]
    end

    def convert_num_to_handRankName(int) #例 8 返り値 "straight flush" 
      case int
      when 1
        "high card"
      when 2
        "one pair"
      when 3
        "two pair"
      when 4
        "three of a kind"
      when 5
        "straight"
      when 6
        "flush"
      when 7
        "fullhouse"
      when 8
        "four of a kind"
      when 9
        "straight flush"
      when 0
        "error hand"
      else 
        "what an error"
      end
    end

    def is_straight(array) #例 [11,12,13,10,14,7,8,9,15], 返り値 [true, [15]] [false, [0]] 
      is_straight = false
      complete_nums = [0]
      array.each do |n|
        straight = true
        n = 1 if n == 14
        4.times do |m|
          unless array.include?(n+m+1)
            straight = false
          end
        end
        if straight == true
          is_straight = true 
          if (n+4) > complete_nums[0] 
            complete_nums[0] = n+4
          end
        end
      end
      [is_straight, complete_nums]
    end

    def convert_hand_to_num(hand) #例 "T", 返り値 10
      n_hand = 0
      case hand
      when "T"
        n_hand = 10
      when "J"
        n_hand = 11
      when "Q"
        n_hand = 12
      when "K"
        n_hand = 13
      when "A"
        n_hand = 14
      else
        n_hand = hand.to_i
      end
      n_hand
    end

    def get_winning_hands(board, my_hand, array_opp_hand)
      if array_opp_hand.count == 1
        my_hand.concat(board)
        my_hand_result = get_handRank(my_hand)
        array_opp_hand[0].concat(board)
        opp_hand_result = get_handRank(array_opp_hand[0])

        if my_hand_result[0] > opp_hand_result[0]
          p "you win by #{my_hand_result[1]}"
          return [[1], my_hand_result]
        elsif my_hand_result[0] < opp_hand_result[0]
          p "rival win by #{opp_hand_result[1]}"
          return [[2], opp_hand_result]
        elsif my_hand_result[0] == opp_hand_result[0]
          my_hand_result[2].each.with_index do |_, idx|
            unless my_hand_result[2][idx] == opp_hand_result[2][idx]
              if my_hand_result[2][idx] > opp_hand_result[2][idx]
                p "you win by #{my_hand_result[1]}, #{my_hand_result[2]} (opp_hand is #{opp_hand_result[2]})"
                return [[1], my_hand_result]
              else
                p "rival win by #{opp_hand_result[1]}, #{opp_hand_result[2]} (my_hand is #{my_hand_result[2]})"
                return [[2], opp_hand_result]
              end
            end
          end
          p "you choped with rival by #{my_hand_result[1]}, #{my_hand_result[2]}"
          return [[1,2], opp_hand_result]
        end
      elsif array_opp_hand.count == 0
        p "argument error. at least 1 opp_hand"
      else
        results = []
        strengh_results = []
        my_hand.concat(board)
        my_hand_result = get_handRank(my_hand)
        p "player_1(you) has #{my_hand_result[1]}"
        results << my_hand_result
        strengh_results << my_hand_result[0]

        nopp = array_opp_hand.count
        nopp.times do |n|
          array_opp_hand[n].concat(board)
          opp_hand_result = get_handRank(array_opp_hand[n])
          p "player_#{n+2} has #{opp_hand_result[1]}"
          results << opp_hand_result
          strengh_results << opp_hand_result[0]
        end
        winning_hand = strengh_results.max
        idx_of_wh = strengh_results.map.with_index { |strengh, i| strengh == winning_hand ? i : nil }.compact
        p "someone win by #{convert_num_to_handRankName(winning_hand)}"
        p "#{idx_of_wh.count} people has #{convert_num_to_handRankName(winning_hand)}"
        m = results[idx_of_wh[0]][2]
        m.count.times do |idx|
          # x回ハイカードを比べていく
          unless idx_of_wh.count == 1
            high_cards = []
            10.times do |n|
              if idx_of_wh.include?(n)
                high_cards << results[n][2][idx]
              else
                high_cards << 0
              end
            end
            winning_kicker = high_cards.max
            idx_of_wh = high_cards.map.with_index { |strengh, i| strengh == winning_kicker ? i : nil }.compact
            if (m.count - 1) == idx && idx_of_wh.count != 1
              winners = idx_of_wh.map{|n|n+1}
              p "#{idx_of_wh.count} player chopped with #{results[idx_of_wh[0]][1]}, #{results[idx_of_wh[0]][2]}, player#{winners}"
              return [winners, results[idx_of_wh[0]]]
            end
          end
        end
        winner_hand = results[idx_of_wh[0]]
        p "player#{idx_of_wh[0]+1} win by #{winner_hand[1]}, #{winner_hand[2]}"
        return [[idx_of_wh[0]+1], winner_hand]
      end
    end

    def get_wh_at_showdown(board, array_hands)
      results = []
      strengh_results = []
      array_hands.each_with_index do |hand, idx|
        if hand == []
          p "player_#{idx+1} is folded"
          results << [0, "folded", []]
          strengh_results << 0
        else
          player_hand = hand
          player_hand.concat(board)
          result = get_handRank(player_hand)
          p "player_#{idx+1} has #{result[1]}"
          results << result
          strengh_results << result[0]
        end
      end
      winning_hand = strengh_results.max
      idx_of_wh = strengh_results.map.with_index { |strengh, i| strengh == winning_hand ? i : nil }.compact
      p "someone win by #{convert_num_to_handRankName(winning_hand)}"
      p "#{idx_of_wh.count} people has #{convert_num_to_handRankName(winning_hand)}"
      m = results[idx_of_wh[0]][2]
      m.count.times do |idx|
        # x回ハイカードを比べていく
        unless idx_of_wh.count == 1
          high_cards = []
          10.times do |n|
            if idx_of_wh.include?(n)
              high_cards << results[n][2][idx]
            else
              high_cards << 0
            end
          end
          winning_kicker = high_cards.max
          idx_of_wh = high_cards.map.with_index { |strengh, i| strengh == winning_kicker ? i : nil }.compact
          if (m.count - 1) == idx && idx_of_wh.count != 1
            winners = idx_of_wh.map{|n|n+1}
            p "#{idx_of_wh.count} player chopped with #{results[idx_of_wh[0]][1]}, #{results[idx_of_wh[0]][2]}, player#{winners}"
            return [winners, results[idx_of_wh[0]]]
          end
        end
      end
      winner_hand = results[idx_of_wh[0]]
      p "player#{idx_of_wh[0]+1} win by #{winner_hand[1]}, #{winner_hand[2]}"
      return [[idx_of_wh[0]+1], winner_hand]
    end

    def get_wh_at_showdown2(board, array_hands) #[[3, "two pair", [8, 5, 10], 1], [1, "high card", [13, 10, 9, 8, 6], 3], [1, "high card", [10, 9, 8, 7, 5], 2], [0, "folded", [], 4]] 
      @bucket_0 = []
      @bucket_1 = []
      @bucket_2 = []
      @bucket_3 = []
      @bucket_4 = []
      @bucket_5 = []
      @bucket_6 = []
      @bucket_7 = []
      @bucket_8 = []
      @bucket_9 = []

      array_hands.each_with_index do |hand, idx|
        if hand == []
          p "player_#{idx+1} is folded"
          @bucket_0 << [0, "folded", [], idx+1]
        else
          player_hand = hand
          player_hand.concat(board)
          result = get_handRank(player_hand) #[7, "fullhouse", [9, 14]]
          p "player_#{idx+1} has #{result[1]}"
          result << idx+1
          eval("@bucket_#{result[0]} << result")
        end
      end
      #強い順に並べる
      results = []
      10.times do |bucket_num|
        eval("@bucket_#{9-bucket_num} = @bucket_#{9-bucket_num}.sort {|(k1, v1, w1), (k2, v2, w2)| w2 <=> w1 }")
        results.concat(eval("@bucket_#{9-bucket_num}"))
      end
      return results
    end

    def get_random_result(int = 100)
      chopped = 0
      hand_results = []
      int.times do |_|
        deck = TRUMP
        deck.shuffle!
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
        opp_hands = []
        #[*1..9].sample.times do |n|
        5.times do |n|
         opp_hands << cards["player_#{n+2}".to_sym]
        end
        p cards[:board]
        p cards[:player_1]
        p opp_hands
        result = get_winning_hands(cards[:board], cards[:player_1], opp_hands)
        unless result[0].count == 1
          chopped += 1 
        end
        hand_results << result[1][0]
      end
      hash_result = hand_results.inject(Hash.new(0)){|hash, a| hash[a] += 1; hash}
      p [int, chopped, hash_result]
    end

    def get_random_board(int = 100)
      board_results = []
      int.times do |_|
        deck = TRUMP
        deck.shuffle!
        board = [deck[20],deck[21],deck[22],deck[23],deck[24]]
        p board
        result = get_handRank(board)
        # if result[0] > 7
        #   p "board good"
        #   sleep(1)
        # end
        board_results << result[0]
      end
      hash_result = board_results.inject(Hash.new(0)){|hash, a| hash[a] += 1; hash}
      p hash_result
      p hash_result.sort
    end

    def get_action(facing_bet = false, nofbet = 0, minimum_bet_amount, prev_bet_amount, current_bet_amount, your_prev_bet_amount, street_stack, your_prev_nofbet, facing_bet_amount)
      if facing_bet
        if your_prev_nofbet == nofbet
          p "you can do \'f\' or \'c\'"
          get = loop do
            print ">> "
            i = $stdin.gets.chomp
            break i if i =~ /[fc]/
            puts "正しいアクションを入力してください"
          end
        else
          if current_bet_amount >= street_stack
            p "you can do \'f\' or \'c\'"
            get = loop do
              print ">> "
              i = $stdin.gets.chomp
              break i if i =~ /[fc]/
              puts "正しいアクションを入力してください"
            end
          else
            p "you can do \'f\', \'c\' or \'r\'"
            get = loop do
              print ">> "
              i = $stdin.gets.chomp
              break i if i =~ /[fcr]/
              puts "正しいアクションを入力してください"
            end
          end
        end
      else
        p "you can do \'x\' or \'b\'"
        get = loop do
          print ">> "
          i = $stdin.gets.chomp
          break i if i =~ /[xb]/
          puts "正しいアクションを入力してください"
        end
      end
       
      case get
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
        bet_amount = loop do
          puts "your can bet #{minimum_bet_amount}~#{street_stack}"
          print ">> "
          i = $stdin.gets.chomp.to_i
          if street_stack < minimum_bet_amount
            return [5, street_stack, nofbet]
          else
            break i if (minimum_bet_amount..street_stack).include?(i)
            puts "正しい額を入力してください"
          end
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
          bet_amount = loop do
            puts "you can raise #{min_raise}~#{street_stack}"
            print ">> "
            i = $stdin.gets.chomp.to_i
            break i if i >= min_raise
            puts "正しい額を入力してください"
          end
          if bet_amount == street_stack
            return [5, bet_amount, nofbet + 1]
          end
          return [4, bet_amount, nofbet + 1]
        end
      else
        p "what an error!"
      end
    end

    def player(int)
      "player_#{int}".to_sym
    end

    def calc_pot_from_betting_status
      # 前のストリートのpot処理
      nof_alive = redis.hget(:game, :nofalive).to_i
      nof_active = redis.hget(:game, :nofactive).to_i
      nofside_pot = redis.hget(:game, :nofside_pot).to_i
      if nof_alive == nof_active
        pot = redis.hget(:game, "side_pot_#{nofside_pot}".to_sym).to_i + redis.hget(:street, :temp_pot).to_i
        redis.hset(:game, "side_pot_#{nofside_pot}".to_sym, pot)
        redis.hset(:street, :temp_pot, 0)
      else #前のストリートで誰かがAI入れた時
        #誰が入れたのか
        alives = []
        allin_men = {}
        redis.hget(:game, :nofpeople).to_i.times do |n| # 全ての人に実行
          if redis.hget(player(n+1), :alive) == "true" # foldしてない
            if redis.hget(player(n+1), :active) == "false" # AI済み or 最後の1人でAIを受けた
              betting = redis.hget(player(n+1), :betting).to_i
              if betting > 0
                allin_men[n+1] = redis.hget(player(n+1), :betting).to_i # AI勝負人に名と金額を連ねる
              end
            end
            # サイドポット獲得権利が現在(前のストリート終了時)のサイドポット番号を上回っているなら
            if redis.hget(player(n+1), :rights_of_side_pot).to_i > redis.hget(:game, :nofside_pot).to_i
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
              redis.hset(player(allin_men[idx+1][0]), :rights_of_side_pot, nofside_pot) # n+1人目の権利を現在で確定
              redis.hset(player(array[0]), :rights_of_side_pot, nofside_pot) # n人目の権利を現在で確定
            else # n人目とn+1人目のオールイン額が一緒でないなら
              redis.hset(player(array[0]), :rights_of_side_pot, nofside_pot) # n人目の権利を現在で確定
              
              side_pot = 0 # サイドポットの金額計算
              allin_amount = 0
              redis.hget(:game, :nofpeople).to_i.times do |n|
                betting = redis.hget(player(n+1), :betting).to_i
                if betting >= array[1]
                  remain = betting - array[1]
                  amount = redis.hget(player(n+1), :amount).to_i - array[1]
                  redis.hset(player(n+1), :amount, amount)
                  redis.hset(player(n+1), :betting, remain)
                  side_pot += array[1]
                else
                  amount = redis.hget(player(n+1), :amount).to_i - redis.hget(player(n+1), :betting).to_i
                  redis.hset(player(n+1), :amount, amount)
                  redis.hset(player(n+1), :betting, 0)
                  side_pot += betting
                end
                allin_amount = array[1]
              end
              allin_men.each do |array|
                array[1] -= allin_amount
              end
              temp_pot = redis.hget(:street, :temp_pot).to_i - side_pot
              redis.hset(:street, :temp_pot, temp_pot)

              redis.hset(:game, "side_pot_#{nofside_pot}".to_sym, side_pot) # サイドポット金額確定
              (idx+1).times do |n|
                alives.delete(allin_men[n][0]) # 生存者から今回のAIをした人らを削除する
              end
              redis.hset(:game, :nofside_pot, nofside_pot + 1) # サイドポット番号を1進める
            end
          else #4人オールインならば、4人目
            redis.hset(player(array[0]), :rights_of_side_pot, nofside_pot) # n人目の権利を現在で確定
            side_pot = redis.hget(:street, :temp_pot) # 残りpot(ヤバイか？)
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
        amount = redis.hget(player(n+1), :amount).to_i - redis.hget(player(n+1), :betting).to_i
        redis.hset(player(n+1), :amount, amount)
        redis.hset(player(n+1), :betting, 0)
      end
    end

    def start
      p "which code?"
      p "1 get complete hand"
      p "2 battle 2 hands"
      p "3 get ramdom result with hands and board"
      p "4 get ramdom board"
      p "5 get action"
      p "6 start game"
      case gets.chomp.to_i
      when 1
        # Hand [Qd Qs]
        # Board [Kd 6c 2c Ks 7s]
        p "your hand?"
        my_hands = gets.chomp.scan(/[TJQKA2-9][shdc]/)
        p "hand = #{my_hands}"
        p "boards?"
        board = gets.chomp.scan(/[TJQKA2-9][shdc]/)
        p "board = #{board}"
        p "rival hand?"
        opp_hands = gets.chomp.scan(/[TJQKA2-9][shdc]/)
        p "rival hand = #{opp_hands}"

        hand = []
        if my_hands.count == 2
          hand.concat(my_hands)
          hand.concat(board)
          hand_name = get_handRank(hand)
          p hand_name
        else
          p "hand must have 2 cards"
        end
      when 2
        # Hand [Qd Qs]
        # Board [Kd 6c 2c Ks 7s]
        p "your hand?"
        my_hands = gets.chomp.scan(/[TJQKA2-9][shdc]/)
        p "hand = #{my_hands}"
        p "boards?"
        board = gets.chomp.scan(/[TJQKA2-9][shdc]/)
        p "board = #{board}"
        p "rival hand?"
        opp_hands = gets.chomp.scan(/[TJQKA2-9][shdc]/)
        p "rival hand = #{opp_hands}"
        
        if (opp_hands.count == 2) && (my_hands.count == 2) && (board.count == 5)
          p get_winning_hands(board, my_hands, opp_hands)
        end
      when 3
        get_random_result(10000)
        return ""
      when 4
        get_random_board(500000)
        return ""
      when 5
        p get_action(false, 0, 2, 0, 0, 0, 200, 0)
      when 6 #ヘッズアップは未実装 
        redis.hset(:game, :number, 1)
        until redis.hget(:game, :number) == "10"
          ####### 初回ゲーム時準備
          if redis.hget(:game, :number) == "1"
            puts "how many people?"
            redis.hset(:game, :nofpeople, gets.chomp.to_i)
            redis.hset(:game, :button, 1)
            redis.hset(:game, :minimum_bet_amount, 2)

            redis.hget(:game, :nofpeople).to_i.times do |n|
              puts "how much player_#{n+1} has?"
              amount = gets.chomp.to_i
              redis.hmset(player(n+1), :name, "player_#{n+1}", :amount, amount, :rights_of_side_pot, 10)
            end
          end
          ####### 毎ゲームの開始準備
          deck = TRUMP
          deck.shuffle!
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
          redis.hset(:street, :nofstreet, 1)
          redis.hset(:game, :board, "")
          redis.hset(:game, :nofalive, redis.hget(:game, :nofpeople))
          redis.hset(:game, :nofactive, redis.hget(:game, :nofpeople))
          redis.hset(:game, :nofside_pot, 1)
          redis.hset(:game, :side_pot_1, 0)
          redis.hset(:game, :side_pot_2, 0)
          redis.hset(:game, :side_pot_3, 0)
          redis.hset(:game, :side_pot_4, 0)
          redis.hset(:game, :side_pot_5, 0)
          redis.hset(:game, :side_pot_6, 0)
          redis.hset(:game, :side_pot_7, 0)
          redis.hset(:game, :side_pot_8, 0)
          redis.hset(:game, :side_pot_9, 0)

          ####### ストリートループ開始  
          until redis.hget(:street, :nofstreet).to_i == 5
            if redis.hget(:game, :nofalive).to_i == 1
              puts "only one person is alive"
              break
            end
            redis.hset(:street, :can_next_street, false)
            redis.hset(:game, :prev_bet_amount, 0)
            ####### pre flop 開始準備
            if redis.hget(:street, :nofstreet).to_i == 1
              redis.hget(:game, :nofpeople).to_i.times do |n|
                card = cards[player(n+1)]
                redis.hset(player(n+1), :hand, card.join(","))
                redis.hset(player(n+1), :prev_nofbet, nil)
                redis.hset(player(n+1), :betting, 0)
                redis.hset(player(n+1), :alive, true)
                redis.hset(player(n+1), :active, true)
              end
              ####### sbとbbの支払い
              #!!!ここでのAIに関して処理していない& 1Big等
              button_num = redis.hget(:game, :button).to_i
              if redis.hget(:game, :nofpeople).to_i < button_num + 1
                redis.hset(:player_1, :betting, 1)
                redis.hset(:player_2, :betting, 2)
              elsif redis.hget(:game, :nofpeople).to_i < button_num + 2
                redis.hset(player(button_num+1), :betting, 1)
                redis.hset(:player_1, :betting, 2)
              else
                redis.hset(player(button_num+1), :betting, 1)
                redis.hset(player(button_num+2), :betting, 2)
              end
              redis.hset(:street ,:temp_pot, 3)
              current_player = button_num

              3.times do 
                if redis.hget(:game, :nofpeople).to_i == current_player
                  current_player = 1
                else
                  current_player += 1
                end
              end
              redis.hset(:street, :nofbet, 1)
              redis.hset(:game, :current_bet_amount, 2)
              redis.hset(:game, :facing_bet_amount, 2)
            ####### post flop 開始準備
            else
              case redis.hget(:street, :nofstreet).to_i
              when 2
                redis.hset(:game, :board, cards[:flop].join(","))
              when 3
                new_board = redis.hget(:game, :board) + "," + (cards[:turn][0])
                redis.hset(:game, :board, new_board)
              when 4
                new_board = redis.hget(:game, :board) + "," + (cards[:river][0])
                redis.hset(:game, :board, new_board)
              end
              
              calc_pot_from_betting_status

              redis.hget(:game, :nofpeople).to_i.times do |n|
                redis.hset(player(n+1), :prev_nofbet, nil)
              end

              #buttonとアクションプレイヤーの設定
              current_player = redis.hget(:game, :button).to_i
              if redis.hget(:game, :nofpeople).to_i == current_player
                current_player = 1
              else
                current_player += 1
              end
              redis.hset(:street, :nofbet, 0)
              redis.hmset(:game, :prev_bet_amount, 0, :current_bet_amount, 0, :facing_bet_amount, 0)
            end
            ####### 各アクション開始
            until redis.hget(:street, :can_next_street) == "true"
              if redis.hget(player(current_player), :alive) == "true" && redis.hget(player(current_player), :active) == "true"
                puts "your_prev_bet_amount"
                p your_prev_bet_amount = redis.hget(player(current_player), :betting).to_i
                puts "your_prev_nofbet"
                p your_prev_nofbet = redis.hget(player(current_player), :prev_nofbet).to_i
                puts "facing_bet"
                p facing_bet = redis.hget(:game, :facing_bet_amount).to_i > your_prev_bet_amount || false
                puts "!!!!!Game!!!!!"
                puts redis.hscan("game",0)
                puts "!!!!!Street!!!!!"
                puts redis.hscan("street",0)
                redis.hget(:game, :nofpeople).to_i.times do |n|
                  puts "!!!!!Player_#{n+1}!!!!!"
                  puts redis.hscan(player(n+1),0)
                end
                puts "It's now player_#{current_player}! you have #{redis.hget(player(current_player), :hand)} and board is #{redis.hget(:game, :board)}"
                result = get_action(facing_bet, redis.hget(:street, :nofbet).to_i, redis.hget(:game, :minimum_bet_amount).to_i, redis.hget(:game, :prev_bet_amount).to_i, redis.hget(:game, :current_bet_amount).to_i, your_prev_bet_amount, redis.hget(player(current_player), :amount).to_i, your_prev_nofbet, redis.hget(:game, :facing_bet_amount).to_i)
                # f→[0,0,nil], x→[1,0,nofbet], c→[2, current_bet_amount,nofbet], b→[3, bet_amount, nofbet + 1], r→[4, bet_amount, nofbet + 1], AI→[5, 条件次第, 条件次第]
                if result[1] > 0
                  pot = (result[1] - redis.hget(player(current_player), :betting).to_i) + redis.hget(:street, :temp_pot).to_i
                  redis.hset(:street, :temp_pot, pot)
                end

                case result[0]
                when 0
                  redis.hset(player(current_player), :rights_of_side_pot, 0)
                  redis.hset(player(current_player), :active, false)
                  nofactive = redis.hget(:game, :nofactive).to_i - 1
                  redis.hset(:game, :nofactive, nofactive)

                  redis.hset(player(current_player), :alive, false)
                  nofalive = redis.hget(:game, :nofalive).to_i - 1
                  redis.hset(:game, :nofalive, nofalive)
                  if nofalive == 1
                    puts "only one person is alive"
                    break
                  end
                when 1
                  # status["player_#{player}".to_sym][:betting] はそのまま
                when 2
                  redis.hset(player(current_player), :betting, result[1])
                  
                  nofactive = redis.hget(:game, :nofactive).to_i
                  if nofactive == 1
                    redis.hset(player(current_player), :active, false)
                    redis.hset(:game, :nofactive, nofactive - 1)
                  end
                when 3..4
                  redis.hset(:game, :prev_bet_amount, redis.hget(:game, :current_bet_amount))
                  redis.hset(:game, :current_bet_amount, result[1])
                  redis.hset(:game, :facing_bet_amount, result[1])
                  nofbet = redis.hget(:street, :nofbet).to_i + 1
                  redis.hset(:street, :nofbet, nofbet)
                  redis.hset(player(current_player), :betting, result[1])

                  nofactive = redis.hget(:game, :nofactive).to_i
                  if nofactive == 1
                    redis.hset(player(current_player), :active, false)
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
                    redis.hset(player(current_player), :betting, result[1])
                  end
                  redis.hset(player(current_player), :active, false)
                  nofactive = redis.hget(:game, :nofactive).to_i - 1
                  redis.hset(:game, :nofactive, nofactive)

                  redis.hset(:game, :prev_bet_amount, redis.hget(:game, :current_bet_amount))
                  redis.hset(:game, :current_bet_amount, result[1])
                  redis.hset(:game, :facing_bet_amount, result[1])
                  nofbet = redis.hget(:street, :nofbet).to_i + 1
                  redis.hset(:street, :nofbet, nofbet)
                  redis.hset(player(current_player), :betting, result[1])
                end
                redis.hset(player(current_player), :prev_nofbet, result[2])
              end
              if redis.hget(:game, :nofpeople).to_i == current_player
                current_player = 1
              else
                current_player += 1
              end
              check_1, check_2, check_3, check_4 = false, false, false, false
              puts "check_1"
              p check_1 = true if redis.hget(player(current_player), :active) == "true"
              puts "check_2"
              p check_2 = true if redis.hget(:game, :facing_bet_amount) == redis.hget(player(current_player), :betting)
              puts "check_3"
              p check_3 = true if redis.hget(:street, :nofbet) == redis.hget(player(current_player), :prev_nofbet)
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
                  puts redis.hscan(player(n+1),0)
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
                  puts redis.hscan(player(n+1),0)
                end
              end
            end
          end

          ####### 結果
          sorted_winners = []
          if redis.hget(:street, :nofstreet).to_i == 5
            array_hands = []
            redis.hget(:game, :nofpeople).to_i.times do |n|
              if redis.hget(player(n+1), :alive) == "true"
                array_hands << redis.hget(player(n+1), :hand).split(",")
              else
                array_hands << []
              end
            end
            sorted_winners = get_wh_at_showdown2(redis.hget(:game, :board).split(","), array_hands)
            puts "player_#{sorted_winners[0][3]} win"
          else
            alive = nil
            redis.hget(:game, :nofpeople).to_i.times do |n|
              if redis.hget(player(n+1), :alive) == "true"
                alive = n + 1
              end
            end
            sorted_winners = [[nil,nil,nil,alive]]
            puts "player_#{sorted_winners[0][3]} win"
          end

          calc_pot_from_betting_status

          rights = redis.hget(:game, :nofpeople).to_i.times.map do |n| # [1, 2, 2, 0]
            redis.hget(player(n+1), :rights_of_side_pot).to_i
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

              sorted_winners.each do |result|
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
                p "player#{gifted_player} win by side_pot_#{n+1}($#{pot})"
                gifted_player.each do |got_player|
                  amount = redis.hget(player(got_player), :amount).to_i
                  if got_player == bad_position
                    redis.hset(player(got_player), :amount, amount + pot + remain)
                  else
                    redis.hset(player(got_player), :amount, amount + pot)
                  end
                end
              end
            end
          end

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
        p "!!!!!!!!!!!!!!finished!!!!!!!!!!!!!!!!"
        puts "!!!!!Game!!!!!"
        puts redis.hscan("game",0)
        puts "!!!!!Street!!!!!"
        puts redis.hscan("street",0)
        redis.hget(:game, :nofpeople).to_i.times do |n|
          puts "!!!!!Player_#{n+1}!!!!!"
          puts redis.hscan(player(n+1),0)
        end
      end
    end
  end 
end