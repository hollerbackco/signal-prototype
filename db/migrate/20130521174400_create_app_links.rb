class CreateAppLinks < ActiveRecord::Migration
  def change
    create_table :app_links do |t|
      t.string :slug
      t.integer :sharer_id
      t.integer :downloads_count, null: false, default: 0
      t.integer :max_downloads
      t.datetime :expires_at
      t.timestamps
    end

    add_index :app_links, :slug, unique: true
  end
end
