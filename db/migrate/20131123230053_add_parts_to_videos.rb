class AddPartsToVideos < ActiveRecord::Migration
  def change
    change_table :videos do |t|
      t.hstore :stitch_request
    end
  end
end
