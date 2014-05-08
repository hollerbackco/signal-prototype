class AddLastActiveAtToUsers < ActiveRecord::Migration
  def up
    add_column :users, :last_active_at, :datetime
  end

  def down
    remove_column :users, :last_active_at
  end
end
