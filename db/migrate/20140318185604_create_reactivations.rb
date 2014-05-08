class CreateReactivations < ActiveRecord::Migration
  def up
    create_table :reactivations do |t|
      t.integer   :user_id
      t.string    :track
      t.string    :track_level
      t.datetime  :last_reactivation
      t.timestamps
    end
  end

  def down
  end
end
