class Card
  #after_create_commit { UserBroadcastJob.perform_later self }
  class << self

    # def push_info(string)
    #   p string
    #   redis.llen("playing_users").times do |n| 
    #     user = redis.lindex("playing_users", n)
    #     ActionCable.server.broadcast "user_#{user}", {action: "info", info: string}
    #   end
    # end
    def get_shuffled_card
      deck = ["As","2s","3s","4s","5s","6s","7s","8s","9s","Ts","Js","Qs","Ks","Ah","2h","3h","4h","5h","6h","7h","8h","9h","Th","Jh","Qh","Kh","Ad","2d","3d","4d","5d","6d","7d","8d","9d","Td","Jd","Qd","Kd","Ac","2c","3c","4c","5c","6c","7c","8c","9c","Tc","Jc","Qc","Kc"]
      deck.shuffle!
      deck
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
    # def get_winning_hands(board, my_hand, array_opp_hand)
    #   if array_opp_hand.count == 1
    #     my_hand.concat(board)
    #     my_hand_result = get_handRank(my_hand)
    #     array_opp_hand[0].concat(board)
    #     opp_hand_result = get_handRank(array_opp_hand[0])

    #     if my_hand_result[0] > opp_hand_result[0]
    #       p "you win by #{my_hand_result[1]}"
    #       return [[1], my_hand_result]
    #     elsif my_hand_result[0] < opp_hand_result[0]
    #       p "rival win by #{opp_hand_result[1]}"
    #       return [[2], opp_hand_result]
    #     elsif my_hand_result[0] == opp_hand_result[0]
    #       my_hand_result[2].each.with_index do |_, idx|
    #         unless my_hand_result[2][idx] == opp_hand_result[2][idx]
    #           if my_hand_result[2][idx] > opp_hand_result[2][idx]
    #             p "you win by #{my_hand_result[1]}, #{my_hand_result[2]} (opp_hand is #{opp_hand_result[2]})"
    #             return [[1], my_hand_result]
    #           else
    #             p "rival win by #{opp_hand_result[1]}, #{opp_hand_result[2]} (my_hand is #{my_hand_result[2]})"
    #             return [[2], opp_hand_result]
    #           end
    #         end
    #       end
    #       p "you choped with rival by #{my_hand_result[1]}, #{my_hand_result[2]}"
    #       return [[1,2], opp_hand_result]
    #     end
    #   elsif array_opp_hand.count == 0
    #     p "argument error. at least 1 opp_hand"
    #   else
    #     results = []
    #     strengh_results = []
    #     my_hand.concat(board)
    #     my_hand_result = get_handRank(my_hand)
    #     p "player_1(you) has #{my_hand_result[1]}"
    #     results << my_hand_result
    #     strengh_results << my_hand_result[0]

    #     nopp = array_opp_hand.count
    #     nopp.times do |n|
    #       array_opp_hand[n].concat(board)
    #       opp_hand_result = get_handRank(array_opp_hand[n])
    #       p "player_#{n+2} has #{opp_hand_result[1]}"
    #       results << opp_hand_result
    #       strengh_results << opp_hand_result[0]
    #     end
    #     winning_hand = strengh_results.max
    #     idx_of_wh = strengh_results.map.with_index { |strengh, i| strengh == winning_hand ? i : nil }.compact
    #     p "someone win by #{convert_num_to_handRankName(winning_hand)}"
    #     p "#{idx_of_wh.count} people has #{convert_num_to_handRankName(winning_hand)}"
    #     m = results[idx_of_wh[0]][2]
    #     m.count.times do |idx|
    #       # x回ハイカードを比べていく
    #       unless idx_of_wh.count == 1
    #         high_cards = []
    #         10.times do |n|
    #           if idx_of_wh.include?(n)
    #             high_cards << results[n][2][idx]
    #           else
    #             high_cards << 0
    #           end
    #         end
    #         winning_kicker = high_cards.max
    #         idx_of_wh = high_cards.map.with_index { |strengh, i| strengh == winning_kicker ? i : nil }.compact
    #         if (m.count - 1) == idx && idx_of_wh.count != 1
    #           winners = idx_of_wh.map{|n|n+1}
    #           p "#{idx_of_wh.count} player chopped with #{results[idx_of_wh[0]][1]}, #{results[idx_of_wh[0]][2]}, player#{winners}"
    #           return [winners, results[idx_of_wh[0]]]
    #         end
    #       end
    #     end
    #     winner_hand = results[idx_of_wh[0]]
    #     p "player#{idx_of_wh[0]+1} win by #{winner_hand[1]}, #{winner_hand[2]}"
    #     return [[idx_of_wh[0]+1], winner_hand]
    #   end
    # end
    def get_wh_at_showdown(board, array_hands) #[[3, "two pair", [8, 5, 10], 1], [1, "high card", [13, 10, 9, 8, 6], 3], [1, "high card", [10, 9, 8, 7, 5], 2], [0, "folded", [], 4]] 
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
          # push_info("player_#{idx+1} is folded")
          @bucket_0 << [0, "folded", [], idx+1]
        else
          player_hand = hand
          player_hand.concat(board)
          result = get_handRank(player_hand) #[7, "fullhouse", [9, 14]]
          # push_info("player_#{idx+1} has #{result[1]}")
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
  end
end
