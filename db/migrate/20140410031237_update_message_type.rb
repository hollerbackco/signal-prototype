class UpdateMessageType < ActiveRecord::Migration
  def change
    Message.update_all(:message_type => 'video')
  end

end
