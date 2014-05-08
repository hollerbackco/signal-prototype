class AddSubtitle < ActiveRecord::Migration
  def change
    change_table :videos do |t|
      t.string :subtitle
    end
  end
end
