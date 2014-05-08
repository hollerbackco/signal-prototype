class AddArchivedColumnToMemberships < ActiveRecord::Migration
  def change
    change_table :memberships do |t|
      t.boolean :is_archived, default: false
    end
  end
end
