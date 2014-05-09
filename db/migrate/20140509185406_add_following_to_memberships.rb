class AddFollowingToMemberships < ActiveRecord::Migration
  change_table :memberships do |t|
    t.boolean :following, :default => false
  end
end
