class CreateDevices < ActiveRecord::Migration
  class Device < ActiveRecord::Base
    attr_accessible :platform, :token

    belongs_to :user
  end

  class User < ActiveRecord::Base
    has_many :devices
  end

  def up
    create_table :devices do |t|
      t.integer :user_id
      t.string :platform
      t.string :platform_version
      t.string :token
    end

    add_index :devices, :user_id
    migrate_device_tokens
  end

  def down
    drop_table :devices
  end

  private

  def migrate_device_tokens
    User.where("device_token is not null").all.each do |user|
      user.devices.create(platform: "ios", token: user.device_token)
    end
  end
end
