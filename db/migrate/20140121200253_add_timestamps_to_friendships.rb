class AddTimestampsToFriendships < ActiveRecord::Migration
  def change
    change_table :friendships do |t|
      t.timestamps
    end
    add_index :friendships, :updated_at
  end
end
