class AddDeviceTokenToUsers < ActiveRecord::Migration
  def change
    change_table :users do |t|
      t.string :device_token
    end
    add_index :users, :device_token
  end
end
