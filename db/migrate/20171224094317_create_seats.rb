class CreateSeats < ActiveRecord::Migration[5.1]
  def change
    create_table :seats do |t|
      t.integer :table_id
      t.integer :user_id
      t.integer :seat_num
      t.timestamps
    end
    add_column :users, :seat_id, :integer
  end
end
