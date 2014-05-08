class AddTrackedToInvite < ActiveRecord::Migration
  def change
    change_table :invites do |t|
      t.boolean :tracked, default: false, null: false
    end
    update_db
  end

  def update_db
     Invite.update_all(:tracked => true)
  end
end
