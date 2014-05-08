class RemoveVideoGuidOnMessages < ActiveRecord::Migration
  def up
    set_video_guids
    remove_column :messages, :video_guid
    add_hstore_index :messages, :content
  end

  def down
    # messages
    execute "ALTER TABLE messages ADD COLUMN video_guid uuid;"
    Message.all.each do |message|
      message.video_guid = message.guid
      message.save
    end
    #execute "ALTER TABLE messages ALTER COLUMN video_guid SET NOT NULL;"
    add_index :messages, [:membership_id, :video_guid], :unique => true
  end

  private

  def set_video_guids
    Message.where("content is not null").find_each do |message|
      if message.video_guid.present?
        message.content["guid"] = message.video_guid
        message.save
      end
    end
  end
end
