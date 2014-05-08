class AddAccessToken < ActiveRecord::Migration
  def change
    change_table :users do |t|
      t.string :access_token
    end
    add_index :users, :access_token, :unique => true
  end
end
