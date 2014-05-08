class NeedsReply < ActiveRecord::Migration
  def change
    change_table :messages do |t|
      t.boolean :needs_reply, :default => true, :null => false
    end
  end
end
