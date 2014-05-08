class AddIndexSeenAtToMessages < ActiveRecord::Migration
  def change
    add_index(:messages, :seen_at)
  end
end
