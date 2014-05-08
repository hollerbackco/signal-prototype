class CreateContacts < ActiveRecord::Migration
  def change
    create_table :contacts do |t|
      t.integer :user_id
      t.string :phone_hashed
      t.string :name
      t.timestamps
    end
    add_index :contacts, :phone_hashed
    add_index :contacts, [:user_id, :phone_hashed]
    add_column :users, :phone_hashed, :string
    add_index :users, :phone_hashed
  end
end
