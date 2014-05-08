class CreateVideos < ActiveRecord::Migration
  def change
    create_table :videos do |t|
      t.integer :user_id
      t.integer :conversation_id
      t.string :filename

      t.timestamps
    end
    add_index :videos, :user_id
    add_index :videos, :conversation_id
  end
end
