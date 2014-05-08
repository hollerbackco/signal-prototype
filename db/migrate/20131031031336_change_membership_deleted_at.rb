class ChangeMembershipDeletedAt < ActiveRecord::Migration
  def up
    add_column :memberships, :deleted_at, :datetime
  end

  def down
    remove_column :memberships, :deleted_at
  end
end
