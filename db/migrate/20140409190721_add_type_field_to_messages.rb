class AddTypeFieldToMessages < ActiveRecord::Migration
  def change
    change_table :messages do |t|
      t.string :message_type
    end
  end
end
