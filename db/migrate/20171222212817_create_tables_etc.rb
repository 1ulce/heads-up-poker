class CreateTablesEtc < ActiveRecord::Migration[5.1]
  def change
    create_table :tables do |t|
      
      t.timestamps
    end
    create_table :games do |t|
      
      t.timestamps
    end
  end
end
