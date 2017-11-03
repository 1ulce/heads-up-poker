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
      when 0
        "high card"
      when 1
        "one pair"
      when 2
        "two pair"
      when 3
        "three of a kind"
      when 4
        "straight"
      when 5
        "flush"
      when 6
        "fullhouse"
      when 7
        "four of a kind"
      when 8
        "straight flush"
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
        p "someone win by #{convert_num_to_handRankName(winning_hand - 1)}"
        p "#{idx_of_wh.count} people has #{convert_num_to_handRankName(winning_hand - 1)}"
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
        if winner_hand[0] == 8
          gets
        end
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
      if winner_hand[0] == 8
        gets
      end
      return [[idx_of_wh[0]+1], winner_hand]
    end

    def get_random_result(int = 100)
      chopped = 0
      hand_results = []
      int.times do |_|
        deck = TRUMP
        deck.shuffle!
        cards = {
          player_1: [deck[0], deck[1]],
          player_2: [deck[2], deck[3]],
          player_3: [deck[4], deck[5]],
          player_4: [deck[6], deck[7]],
          player_5: [deck[8], deck[9]],
          player_6: [deck[10], deck[11]],
          player_7: [deck[12], deck[13]],
          player_8: [deck[14], deck[15]],
          player_9: [deck[16], deck[17]],
          player_10: [deck[18], deck[19]],
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
          return [4, bet_amount, nofbet + 1]
        end
      else
        p "what an error!"
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
        redis.set(:game, {})
        status[:game][:number] = 1
        until status[:game][:number] == 3
      ####### 初回ゲーム時準備
          if status[:game][:number] == 1
            puts "how many people?"
            status[:game][:nofpeople] = gets.chomp.to_i
            
            status[:game][:button] = 1
            status[:game][:minimum_bet_amount] = 2

            status[:game][:nofpeople].times do |n|
              puts "how much player_#{n+1} has?"
              amount = gets.chomp.to_i
              status["player_#{n+1}".to_sym] = {name: "player_#{n+1}", amount: amount, street_stack: amount}
            end
          end
      ####### 毎ゲームの開始準備
          deck = TRUMP
          deck.shuffle!
          cards = {
            player_1: [deck[0], deck[1]],
            player_2: [deck[2], deck[3]],
            player_3: [deck[4], deck[5]],
            player_4: [deck[6], deck[7]],
            player_5: [deck[8], deck[9]],
            player_6: [deck[10], deck[11]],
            player_7: [deck[12], deck[13]],
            player_8: [deck[14], deck[15]],
            player_9: [deck[16], deck[17]],
            player_10: [deck[18], deck[19]],
            board: [deck[20],deck[21],deck[22],deck[23],deck[24]],
            flop: [deck[20],deck[21],deck[22]],
            turn: [deck[23]],
            river: [deck[24]],
            rit_board: [deck[25],deck[26],deck[27],deck[28],deck[29]],
            rit_flop: [deck[25],deck[26],deck[27]],
            rit_turn: [deck[28]],
            rit_river: [deck[29]],
          }
          status[:street][:nofstreet] = 1
          status[:game][:board] = []
          status[:game][:nofalive] = status[:game][:nofpeople]
          status[:game][:pot_1] = 0

      ####### ストリートループ開始  
          until status[:street][:nofstreet] == 5
            if status[:game][:nofalive] == 1
              puts "only one person is alive"
              break
            end
            status[:street][:can_next_street] = false
            status[:game][:prev_bet_amount] = 0
      ####### pre flop 開始準備
            if status[:street][:nofstreet] == 1
              status[:game][:nofpeople].times do |n|
                card = cards["player_#{n+1}".to_sym]
                status["player_#{n+1}".to_sym][:hand] = card
                status["player_#{n+1}".to_sym][:prev_nofbet] = nil
                status["player_#{n+1}".to_sym][:betting] = 0
                status["player_#{n+1}".to_sym][:alive] = true
              end
              if status[:game][:nofpeople] < status[:game][:button] + 1
                status[:player_1][:betting] = 1
                status[:player_2][:betting] = 2
              elsif status[:game][:nofpeople] < status[:game][:button] + 2
                status["player_#{status[:game][:button] + 1}".to_sym][:betting] = 1
                status[:player_1][:betting] = 2
              else
                status["player_#{status[:game][:button] + 1}".to_sym][:betting] = 1
                status["player_#{status[:game][:button] + 2}".to_sym][:betting] = 2
              end
              status[:street][:temp_pot] = 3 
              player = status[:game][:button]
              3.times do 
                if status[:game][:nofpeople] == player
                  player = 1
                else
                  player += 1
                end
              end
              status[:street][:nofbet] = 1
              status[:game][:current_bet_amount] = 2
              status[:game][:facing_bet_amount] = status[:game][:current_bet_amount]
      ####### post flop 開始準備
            else
              case status[:street][:nofstreet]
              when 2
                status[:game][:board] = status[:game][:board].concat(cards[:flop])
              when 3
                status[:game][:board] = status[:game][:board].concat(cards[:turn])
              when 4
                status[:game][:board] = status[:game][:board].concat(cards[:river])
              end
              status[:game][:nofpeople].times do |n|
                status["player_#{n+1}".to_sym][:amount] -= status["player_#{n+1}".to_sym][:betting]
                status["player_#{n+1}".to_sym][:prev_nofbet] = nil
                status["player_#{n+1}".to_sym][:betting] = 0
                status["player_#{n+1}".to_sym][:street_stack] = status["player_#{n+1}".to_sym][:amount]
              end
              status[:game][:pot_1] += status[:street][:temp_pot]
              status[:street][:temp_pot] = 0
              player = status[:game][:button]
              if status[:game][:nofpeople] == player
                player = 1
              else
                player += 1
              end
              status[:street][:nofbet] = 0
              status[:game][:prev_bet_amount] = 0
              status[:game][:current_bet_amount] = 0
              status[:game][:facing_bet_amount] = 0
            end
      ####### 各アクション開始
            until status[:street][:can_next_street]
              if status["player_#{player}".to_sym][:alive]
                puts "your_prev_bet_amount"
                p your_prev_bet_amount = status["player_#{player}".to_sym][:betting]
                puts "your_prev_nofbet"
                p your_prev_nofbet = status["player_#{player}".to_sym][:prev_nofbet]
                puts "facing_bet"
                p facing_bet = status[:game][:facing_bet_amount] > your_prev_bet_amount || false
                puts status
                puts "It's now player_#{player}! you have #{status["player_#{player}".to_sym][:hand]} and board is #{status[:game][:board]}"
            ######
            ######
                result = get_action(facing_bet, status[:street][:nofbet], status[:game][:minimum_bet_amount], status[:game][:prev_bet_amount], status[:game][:current_bet_amount], your_prev_bet_amount, status["player_#{player}".to_sym][:street_stack], your_prev_nofbet, status[:game][:facing_bet_amount])
            ######
            ######
                # f→[0,0,nil], x→[1,0,nofbet], c→[2, current_bet_amount,nofbet], b→[3, bet_amount, nofbet + 1], r→[4, bet_amount, nofbet + 1], AI→[5, ~~, ~~]
                if result[1] > 0
                  status[:street][:temp_pot] += result[1] - status["player_#{player}".to_sym][:betting]
                end

                case result[0]
                when 0
                  status["player_#{player}".to_sym][:alive] = false
                  status[:game][:nofalive] -= 1
                  if status[:game][:nofalive] == 1
                    puts "only one person is alive"
                    break
                  end
                when 1
                  # status["player_#{player}".to_sym][:betting] はそのまま
                when 2
                  status["player_#{player}".to_sym][:betting] = result[1]
                when 3
                  status[:game][:prev_bet_amount] = status[:game][:current_bet_amount]
                  status[:game][:current_bet_amount] = result[1]
                  status[:game][:facing_bet_amount] = status[:game][:current_bet_amount]
                  status[:street][:nofbet] += 1 
                  status["player_#{player}".to_sym][:betting] = result[1]
                when 4
                  status[:game][:prev_bet_amount] = status[:game][:current_bet_amount]
                  status[:game][:current_bet_amount] = result[1]
                  status[:game][:facing_bet_amount] = status[:game][:current_bet_amount]
                  status[:street][:nofbet] += 1 
                  status["player_#{player}".to_sym][:betting] = result[1]
                when 5
                  if result[2] == status[:street][:nofbet]
                    # prev_bet_amountはこのまま
                    # current_bet_amountはこのまま
                    p status[:game][:facing_bet_amount] = result[1] if status[:game][:facing_bet_amount] < result[1]
                    # nofbetはこのまま
                    status["player_#{player}".to_sym][:betting] = result[1]
                  else
                    status[:game][:prev_bet_amount] = status[:game][:current_bet_amount]
                    status[:game][:current_bet_amount] = result[1]
                    status[:game][:facing_bet_amount] = status[:game][:current_bet_amount]
                    status[:street][:nofbet] += 1 
                    status["player_#{player}".to_sym][:betting] = result[1]
                  end
                end
                status["player_#{player}".to_sym][:prev_nofbet] = result[2]
              end
              if status[:game][:nofpeople] == player
                player = 1
              else
                player += 1
              end
              check_1, check_2, check_3 = false
              puts "check_1"
              p check_1 = true if status["player_#{player}".to_sym][:alive] == true
              puts "check_2"
              p check_2 = true if status[:game][:facing_bet_amount] == status["player_#{player}".to_sym][:betting]
              puts "check_3"
              p check_3 = true if status[:street][:nofbet] == status["player_#{player}".to_sym][:prev_nofbet]
              if check_1 && check_2 && check_3
                status[:street][:can_next_street] = true
                status[:street][:nofstreet] += 1
                puts status
                puts "go to next street"
              end
            end
          end
      ####### 結果
          winner = []
          if status[:street][:nofstreet] == 5
            array_hands = []
            status[:game][:nofpeople].times do |n|
              if status["player_#{n+1}".to_sym][:alive]
                array_hands << status["player_#{n+1}".to_sym][:hand]
              else
                array_hands << []
              end
            end
            result = get_wh_at_showdown(status[:game][:board], array_hands)
            puts "player_#{result[0][0]} win"
            winner = result[0]
          else
            alive = nil
            status[:game][:nofpeople].times do |n|
              if status["player_#{n+1}".to_sym][:alive]
                alive = n
              end
            end
            puts "player_#{alive+1} win"
            winner = [alive+1]
          end
      ####### 次の準備
          if winner.count == 1
            status[:game][:pot_1] += status[:street][:temp_pot]
            status["player_#{winner[0]}".to_sym][:amount] = status["player_#{winner[0]}".to_sym][:amount] + status[:game][:pot_1] - status["player_#{winner[0]}".to_sym][:betting]
            status["player_#{winner[0]}".to_sym][:street_stack] = status["player_#{winner[0]}".to_sym][:amount]
            status["player_#{winner[0]}".to_sym][:betting] = 0
            status[:game][:nofpeople].times do |n|
              status["player_#{n+1}".to_sym][:amount] -= status["player_#{n+1}".to_sym][:betting]
            end
          else
            p "未実装"
            raise
          end
          status[:game][:number] += 1
          button_player = status[:game][:button]
          if status[:game][:nofpeople] == button_player
            button_player = 1
          else
            button_player += 1
          end
          status[:game][:button] = button_player
        end
        p status
      end
    end
  end 
end