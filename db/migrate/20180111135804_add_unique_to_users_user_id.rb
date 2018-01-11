class AddUniqueToUsersUserId < ActiveRecord::Migration[5.1]
  def change
    remove_column :users, :user_id
    add_column :users, :user_id, :string, unique: true
  end
end