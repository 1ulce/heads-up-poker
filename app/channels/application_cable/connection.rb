module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :user_id
    def connect
      self.user_id = cookies[:_session_id]
    end
  end
end
