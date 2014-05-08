class AddSenderId < ActiveRecord::Migration
  def up
     execute "UPDATE messages as m set sender_id=v.user_id from videos as v where cast(m.content->'guid' as uuid) = v.guid"
  end

  def down
  end
end
