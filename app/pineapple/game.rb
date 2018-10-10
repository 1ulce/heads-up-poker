def get_card_name(int) #例 6 返り値 "7s" 0~51
  get_card_rank(int).to_s + get_card_suit(int)
end

def get_card_rank(int) #例 6 返り値 7   0~51
  int%13+1
end

def get_card_suit(int) #例 6 返り値 "s"   0~51
  case int/13
  when 0 then return "s"
  when 1 then return "h"
  when 2 then return "d"
  when 3 then return "c"
  end
end

def get_shuffled_card
  deck = [*0..51]
  deck.shuffle
end

def get_maximum_handRank(array) #例 ["Ac","As","Ts","9h","9h","9s","2d"] 返り値 [7, "fullhouse", [9, 14]]

end

def can_straight_flush(array) #例 [1,2,3,4,5,6] 返り値 [6,5,4,3,2]
  spades = (array.select {|a| 0 <= a < 13 }).sort! {|a, b| a <=> b }
  hearts = (array.select {|a| 13 <= a < 26 }).sort! {|a, b| a <=> b }
  diamonds = (array.select {|a| 26 <= a < 39 }).sort! {|a, b| a <=> b }
  clubs = (array.select {|a| 39 <= a < 52 }).sort! {|a, b| a <=> b }




def get_maximum_handRank(array) #例 ["Ac","As","Ts","9h","9h","9s","2d"] 返り値 [7, "fullhouse", [9, 14]]
  is_flush = false
  is_straight = false
  suit = []
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
      suit << [sym]
      is_flush = true
      judge[sym][1].sort! {|a, b| b <=> a }
      flag, complete_straight_nums = is_straight(judge[sym][1])
      if flag
        complete_hands = []
        5.times do |n|
          complete_hands << convert_num_to_hand(complete_straight_nums - n) + sym
        end
        complete_nums = complete_straight_nums
        return [9, "straight flush", complete_nums, complete_hands]
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
    kicker = high_cards
    kicker.delete(four_card[0])
    complete_nums = [four_card[0],kicker[0]]
    s_hand = 
    complete_hands = ["s","h","d","c"].map{|sym| convert_num_to_hand(four_card[0]) + sym}

    return [8, "four of a kind", complete_nums]
  end
  if three_card.count > 0 && pair.count > 1
    kicker = pair
    kicker.delete(three_card[0])
    complete_nums = [three_card[0],kicker[0]]
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
    kicker = high_cards
    kicker.delete(three_card[0])
    complete_nums = [three_card[0],kicker[0],kicker[1]]
    return [4, "three of a kind", complete_nums]
  end
  if pair.count > 1
    kicker = high_cards
    kicker.delete(pair[0])
    kicker.delete(pair[1])
    complete_nums = [pair[0],pair[1],kicker[0]]
    return [3, "two pair", complete_nums]
  end
  if pair.count == 1
    kicker = high_cards
    kicker.delete(pair[0])
    complete_nums = [pair[0],kicker[0],kicker[1],kicker[2]]
    return [2, "one pair", complete_nums]
  end
  complete_nums = high_cards.take(5)
  return [1, "high card", complete_nums]
end

def get_maximum_topRank(array) #例 ["Ac","As","Ts","9h","9h","9s","2d"] 返り値 [7, "fullhouse", [9, 14]]
  complete_flush_nums = []
  num_hands = []

  three_card = num_hands.inject(Hash.new(0)){|h, i| h[i] += 1; h }.reject{|k, v| v <= 2 }.keys.sort {|a, b| b <=> a }
  pair = num_hands.inject(Hash.new(0)){|h, i| h[i] += 1; h }.reject{|k, v| v <= 1 }.keys.sort {|a, b| b <=> a }
  high_cards = num_hands.sort {|a, b| b <=> a }

  if three_card.count == 1
    complete_nums = [three_card[0]]
    return [4, "three of a kind", complete_nums]
  end
  if pair.count == 1
    high_cards.delete(pair[0])
    complete_nums = [pair[0],high_cards[0]]
    return [2, "one pair", complete_nums]
  end
  complete_nums = high_cards.take(3)
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

def convert_num_to_hand(num) #例 10, 返り値 "T"
  hand = 0
  case num
  when 1
    hand = "A"
  when 10
   hand = "T"
  when 11
    hand = "J"
  when 12
    hand = "Q"
  when 13
    hand = "K"
  when 14
    hand = "A"
  else
    hand = hand.to_s
  end
  hand
end


fantasy_cards = get_shuffled_card.shuffle.take(14)
get_maximum_handRank(fantasy_cards)


14枚のカードを選ぶ

「
14枚のカード→最高役を取り出す
9枚のカード→最高役を取り出す
4枚のカード→最高役を取り出す
」
点数計算をする


