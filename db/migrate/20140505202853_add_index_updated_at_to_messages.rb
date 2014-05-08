class AddIndexUpdatedAtToMessages < ActiveRecord::Migration
  def change
    add_index(:messages, :updated_at)
  end
end
