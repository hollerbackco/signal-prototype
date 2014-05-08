class CreateMessages < ActiveRecord::Migration
  class ::Message < ActiveRecord::Base
    belongs_to :membership
    serialize :content, ActiveRecord::Coders::Hstore
  end

  def up
    create_table :messages do |t|
      t.integer :membership_id
      t.boolean :is_sender
      t.integer :sender_id
      t.string :sender_name
      t.string :content_guid
      t.hstore :content
      t.datetime :sent_at
      t.datetime :seen_at
      t.datetime :deleted_at
      t.timestamps
    end
    add_index :messages, :membership_id
    add_index :messages, :sent_at

    add_column :memberships, :last_message_at, :datetime
    add_column :memberships, :most_recent_thumb_url, :string

    add_index :memberships, :last_message_at
    create_messages
  end

  def down
    drop_table :messages
    remove_column :memberships, :last_message_at
    remove_column :memberships, :most_recent_thumb_url
  end

  private

  def create_messages
    ActiveRecord::Base.record_timestamps = false
    counter = 0
    counter2 = 0
    Video.unscoped.find_each do |video|
      p counter = counter + 1
      next if video.conversation.blank?
      next if video.filename.blank?
      next if video.user.blank?

      conversation = video.conversation
      conversation.members.each do |member|
        sender = video.user
        membership = Membership.where(:conversation_id => conversation.id, :user_id => member.id).first

        message = ::Message.create(
          membership_id: membership.id,
          is_sender: (sender == member),
          sender_id: sender.id,
          sender_name: sender.also_known_as(for: member),
          content_guid: video.id,
          content: video.content_hash,
          seen_at: Time.now,
          sent_at: video.created_at,
          created_at: video.created_at,
          updated_at: Time.now,
          deleted_at: nil
        )

        p "m#{counter2 = counter2 + 1}"
      end
    end
    ActiveRecord::Base.record_timestamps = true
  end
end
