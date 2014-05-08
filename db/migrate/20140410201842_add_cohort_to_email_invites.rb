class AddCohortToEmailInvites < ActiveRecord::Migration
  def change
    change_table :email_invites do |t|
      t.string :cohort
    end
  end
end
