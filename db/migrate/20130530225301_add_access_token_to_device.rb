class AddAccessTokenToDevice < ActiveRecord::Migration
  class User < ActiveRecord::Base
    attr_accessible :access_token

    has_many :devices
  end

  class Device < ActiveRecord::Base
    attr_accessible :access_token, :platform
  end

  def up
    add_column :devices, :access_token, :string
    add_index :devices, :access_token, :unique => true

    move_user_access_tokens
  end

  def down
    remove_column :devices, :access_token
  end

  private

  def move_user_access_tokens
    User.all.each do |user|
      user.devices.create(platform: "general", access_token: user.access_token)
    end
  end
end
