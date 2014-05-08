class AddProgressToVideos < ActiveRecord::Migration
  class Video < ActiveRecord::Base
    def ready!
      in_progress = false
      save!
    end

    def processing!
      in_progress = true
      save!
    end
  end

  def up
    add_column :videos, :in_progress, :boolean, null: false, default: true

    ActiveRecord::Base.record_timestamps = false

    Video.all.each {|v| v.ready!}

    ActiveRecord::Base.record_timestamps = true
  end

  def down
    remove_column :videos, :in_progrees
  end
end
