class AddSegmentsToAppLinks < ActiveRecord::Migration

  class AppLink < ActiveRecord::Base
    attr_accessible :segment
  end

  def up
    change_table :app_links do |t|
      t.string :segment
    end
    remove_index :app_links, :slug
    add_index :app_links, [:slug, :segment], unique: true
    update_old_app_links
  end

  def down
    remove_index :app_links, [:slug, :segment]
    remove_column :app_links, :segment
    add_index :app_links, :slug, unique: true
  end

  def update_old_app_links
    AppLink.all.each do |link|
      link.update_attribute :segment, "ios"
    end
  end
end
