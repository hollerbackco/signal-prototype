class AddMostRecentSubtitleToMemberships < ActiveRecord::Migration
  def change
    change_table :memberships do |t|
      t.string :most_recent_subtitle
    end
  end
end
