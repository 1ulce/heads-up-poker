class User < ApplicationRecord
  #after_create_commit { UserBroadcastJob.perform_later self }
  def name

  end
  def stream

  end
end
