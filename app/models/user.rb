class User < ApplicationRecord
  #after_create_commit { UserBroadcastJob.perform_later self }
  # attr_accessor :name
  include Redis::Objects
  belongs_to :table, optional: true
  belongs_to :game, optional: true
  belongs_to :seat, optional: true

  value :hand
  value :prev_bet_num
  value :betting
  value :amount
  value :rights_of_side_pot

  def stream(data, to = "user_#{self.user_id}")
    ActionCable.server.broadcast to, data
  end
end
