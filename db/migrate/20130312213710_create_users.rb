class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :email
      t.string :name
      t.string :phone
      t.string :phone_normalized
      t.string :password_digest

      t.timestamps
    end
    add_index :users, :email
    add_index :users, :phone_normalized
  end
end
