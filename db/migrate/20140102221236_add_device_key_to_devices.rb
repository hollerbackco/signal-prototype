class AddDeviceKeyToDevices < ActiveRecord::Migration
  def change
    change_table :devices do |t|
      t.string :device_key
    end
    add_index :devices, :device_key
  end
end
