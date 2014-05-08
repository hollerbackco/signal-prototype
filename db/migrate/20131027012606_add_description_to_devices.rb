class AddDescriptionToDevices < ActiveRecord::Migration
  def up
    add_column :devices, :description, :string
  end

  def down
    remove_column :devices, :description
  end
end
