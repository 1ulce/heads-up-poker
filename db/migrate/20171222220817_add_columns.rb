class AddColumns < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :table_id, :integer
    add_column :users, :game_id, :integer
    add_column :games, :table_id, :integer
  end
end
