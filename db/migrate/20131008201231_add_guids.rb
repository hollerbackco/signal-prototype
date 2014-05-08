class AddGuids < ActiveRecord::Migration
  class MigratingMessage < ActiveRecord::Base
    self.table_name = "messages"

    def video
      MigratingVideo.find(content_guid.to_i)
    end
  end

  class MigratingVideo < ActiveRecord::Base
    self.table_name = "videos"
  end

  def up
    # videos
    execute "ALTER TABLE videos ADD COLUMN guid uuid DEFAULT uuid_generate_v4() NOT NULL;"

    # messages
    execute "ALTER TABLE messages ADD COLUMN video_guid uuid;"

    MigratingMessage.all.each do |message|
      video = message.video

      if video
        p video.guid
        message.video_guid = video.guid
      end

      message.save
    end

    execute "ALTER TABLE messages ALTER COLUMN video_guid SET NOT NULL;"
    execute "ALTER TABLE messages DROP COLUMN content_guid;"
    add_index :videos, :guid, :unique => true
    add_index :messages, :video_guid

    MigratingMessage.select("membership_id, video_guid, array_agg(id) as ids, count(*) as message_count")
      .group("membership_id, video_guid")
      .having("count(*) > 1").each do |m|
        ids = m[:ids].gsub(/[{}]/, "").split(",")
        ids.pop
        MigratingMessage.find(ids).each(&:destroy)
      end

    add_index :messages, [:membership_id, :video_guid], :unique => true
  end

  def down
    execute "ALTER TABLE videos DROP COLUMN guid;"
    execute "ALTER TABLE messages DROP COLUMN video_guid;"
  end
end
