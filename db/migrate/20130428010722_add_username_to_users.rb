class AddUsernameToUsers < ActiveRecord::Migration
  def up
    add_column :users, :username, :string
    set_usernames_from_email
    add_index :users, :username, :unique => true
  end

  def down
    remove_column :users, :username
  end

  private

  def set_usernames_from_email
    User.all.each do |user|
      email = user.email.split("@").first
      user.username = email
      user.save!
    end
  end
end
