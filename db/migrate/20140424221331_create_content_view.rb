class CreateContentView < ActiveRecord::Migration
  def up
    execute <<-SQL
                CREATE VIEW contents AS
                            select id, user_id, conversation_id, filename, created_at, updated_at, 'Video' as type from videos
                            union all
                            select id, user_id, conversation_id, text, created_at, updated_at, 'Text' as type from texts;
            SQL
  end

  def down
  end
end
