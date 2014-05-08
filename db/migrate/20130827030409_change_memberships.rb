class ChangeMemberships < ActiveRecord::Migration
  def up
    add_column :memberships, :name, :string
    update_memberships
  end

  def down
    remove_column :memberships, :name
  end

  def update_memberships
    ActiveRecord::Base.record_timestamps = false
    Membership.all.each do |m|
      next if m.messages.empty?
      message = m.messages.first
      next if message.thumb_url.blank?

      p m.name
      m.most_recent_thumb_url = message.thumb_url
      m.last_message_at = message.sent_at
      p m.most_recent_thumb_url
      m.save!
    end
    ActiveRecord::Base.record_timestamps = true
  end
end
