class AddCohortToInvites < ActiveRecord::Migration
  def change
    change_table :invites do |t|
      t.string :cohort
    end
  end
end
