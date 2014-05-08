class CreateWaitlisters < ActiveRecord::Migration
  def change
    create_table :waitlisters do |t|
      t.string :email
      t.timestamps
    end

    add_index :waitlisters, :email
  end
end
