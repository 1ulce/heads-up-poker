class Seat < ApplicationRecord
  #after_create_commit { UserBroadcastJob.perform_later self }
  # attr_accessor :name
  include Redis::Objects
  belongs_to :table, optional: true
  has_one :user
end
