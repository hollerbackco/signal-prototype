class CreateMemberships < ActiveRecord::Migration
  def change
    create_table :memberships do |t|
      t.integer :user_id
      t.integer :conversation_id

      t.timestamps
    end
    add_index :memberships, [:user_id, :conversation_id], :unique => true
    add_index :memberships, [:conversation_id, :user_id], :unique => true
  end
end
