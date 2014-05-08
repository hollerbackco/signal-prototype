class CreateConversations < ActiveRecord::Migration
  def change
    create_table :conversations do |t|
      t.integer :creator_id
      t.string :name
      t.integer :videos_count

      t.timestamps
    end
  end
end
