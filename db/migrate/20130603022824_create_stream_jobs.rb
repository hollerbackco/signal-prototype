class CreateStreamJobs < ActiveRecord::Migration
  def up
    create_table :stream_jobs do |t|
      t.integer :video_id
      t.string :master_playlist
      t.string :state, :null => false, :default => "in_progress"
      t.string :job_id
    end

    add_column :videos, :streamname, :string
    add_index :stream_jobs, :video_id
    add_index :stream_jobs, :job_id
  end

  def down
    drop_table :streams
    remove_column :videos, :streamname
  end
end
