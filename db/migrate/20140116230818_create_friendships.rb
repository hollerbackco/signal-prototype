class CreateFriendships < ActiveRecord::Migration
  def up
    create_table :friendships do |t|
      t.integer :user_id
      t.integer :friend_id
    end

    add_index :friendships, :user_id
    add_index :friendships, :friend_id
  end

  def down
    remove_table :friendships
  end
end
