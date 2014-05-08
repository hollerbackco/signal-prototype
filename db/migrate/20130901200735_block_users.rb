class BlockUsers < ActiveRecord::Migration
  def up
    add_column :users, :muted, :text
  end

  def down
    remove_column :users, :muted, :text
  end
end
