class CreateEmailInvites < ActiveRecord::Migration
  def up
    create_table :email_invites do |t|
      t.string    :email
      t.integer   :inviter_id
      t.boolean   :accepted, default: false, null: false

      t.timestamps
    end
    add_index :email_invites, :email
  end

  def down
  end
end
