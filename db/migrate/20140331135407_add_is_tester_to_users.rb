class AddIsTesterToUsers < ActiveRecord::Migration
  def change
    change_table :users do |t|
      t.boolean :is_tester, default: false, null: false
    end
  end
end
