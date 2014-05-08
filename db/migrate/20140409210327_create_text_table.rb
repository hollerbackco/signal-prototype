class CreateTextTable < ActiveRecord::Migration
    def up
      create_table :texts do |t|
        t.integer :user_id
        t.integer :conversation_id
        t.string  :guid
        t.string  :text
        t.timestamps
      end
      add_index :texts, :guid
    end

    def down
      drop_table :texts
    end
end
