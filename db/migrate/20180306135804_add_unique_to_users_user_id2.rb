class AddUniqueToUsersUserId2 < ActiveRecord::Migration[5.1]
  def  change
    add_index  :users, :user_id, unique: true
  end
end