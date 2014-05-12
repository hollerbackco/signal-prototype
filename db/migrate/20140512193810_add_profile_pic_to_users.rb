class AddProfilePicToUsers < ActiveRecord::Migration
  def change
    change_table :users do |t|
      t.string :profile_pic_url
    end
  end
end
