class CreateInvites < ActiveRecord::Migration
  def change
    create_table :invites do |t|
      t.string :phone
      t.integer :inviter_id
      t.integer :conversation_id
      t.boolean :accepted, default: false, null: false

      t.timestamps
    end
    add_index :invites, :phone
    add_index :invites, :conversation_id
  end
end
