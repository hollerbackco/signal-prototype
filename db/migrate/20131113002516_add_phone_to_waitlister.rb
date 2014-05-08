class AddPhoneToWaitlister < ActiveRecord::Migration
  def up
    add_column :waitlisters, :phone, :string
    add_column :invites, :waitlisted, :boolean
  end

  def down
    remove_column :waitlisters, :phone
  end
end
