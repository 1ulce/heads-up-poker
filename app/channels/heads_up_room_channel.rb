class HeadsUpRoomChannel < ApplicationCable::Channel
  def subscribed
    # stream_from "some_channel"
    #stream_from "heads_up_room_channel"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def entered
    stream_from "room_1"
    user = User.new
    user.user_id = user_id
    puts user.user_id
    user.save    
  end

  def finished
  end

  def put_message(data)
    ActionCable.server.broadcast "room_1", data
  end

  def stop_stream
    stop_all_streams
  end
end
