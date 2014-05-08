class AddCohortToUsers < ActiveRecord::Migration
  def change
    change_table :users do |t|
      t.string :cohort
    end
  end
end
