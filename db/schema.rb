# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20140121200253) do

  create_table "app_links", :force => true do |t|
    t.string   "slug"
    t.integer  "sharer_id"
    t.integer  "downloads_count", :default => 0, :null => false
    t.integer  "max_downloads"
    t.datetime "expires_at"
    t.datetime "created_at",                     :null => false
    t.datetime "updated_at",                     :null => false
    t.string   "segment"
  end

  add_index "app_links", ["slug", "segment"], :name => "index_app_links_on_slug_and_segment", :unique => true

  create_table "contacts", :force => true do |t|
    t.integer  "user_id"
    t.string   "phone_hashed"
    t.string   "name"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  add_index "contacts", ["phone_hashed"], :name => "index_contacts_on_phone_hashed"
  add_index "contacts", ["user_id", "phone_hashed"], :name => "index_contacts_on_user_id_and_phone_hashed"

  create_table "conversations", :force => true do |t|
    t.integer  "creator_id"
    t.string   "name"
    t.integer  "videos_count"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  create_table "devices", :force => true do |t|
    t.integer "user_id"
    t.string  "platform"
    t.string  "platform_version"
    t.string  "token"
    t.string  "access_token"
    t.string  "description"
    t.string  "device_key"
  end

  add_index "devices", ["access_token"], :name => "index_devices_on_access_token", :unique => true
  add_index "devices", ["device_key"], :name => "index_devices_on_device_key"
  add_index "devices", ["user_id"], :name => "index_devices_on_user_id"

  create_table "friendships", :force => true do |t|
    t.integer  "user_id"
    t.integer  "friend_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "friendships", ["friend_id"], :name => "index_friendships_on_friend_id"
  add_index "friendships", ["updated_at"], :name => "index_friendships_on_updated_at"
  add_index "friendships", ["user_id"], :name => "index_friendships_on_user_id"

  create_table "invites", :force => true do |t|
    t.string   "phone"
    t.integer  "inviter_id"
    t.integer  "conversation_id"
    t.boolean  "accepted",        :default => false, :null => false
    t.datetime "created_at",                         :null => false
    t.datetime "updated_at",                         :null => false
    t.boolean  "waitlisted"
  end

  add_index "invites", ["conversation_id"], :name => "index_invites_on_conversation_id"
  add_index "invites", ["phone"], :name => "index_invites_on_phone"

  create_table "memberships", :force => true do |t|
    t.integer  "user_id"
    t.integer  "conversation_id"
    t.datetime "created_at",            :null => false
    t.datetime "updated_at",            :null => false
    t.datetime "last_message_at"
    t.string   "most_recent_thumb_url"
    t.string   "name"
    t.string   "most_recent_subtitle"
    t.datetime "deleted_at"
  end

  add_index "memberships", ["conversation_id", "user_id"], :name => "index_memberships_on_conversation_id_and_user_id", :unique => true
  add_index "memberships", ["last_message_at"], :name => "index_memberships_on_last_message_at"
  add_index "memberships", ["user_id", "conversation_id"], :name => "index_memberships_on_user_id_and_conversation_id", :unique => true

# Could not dump table "messages" because of following StandardError
#   Unknown type 'hstore' for column 'content'

  create_table "pledgers", :force => true do |t|
    t.string  "name"
    t.string  "username"
    t.string  "auth_token"
    t.string  "auth_secret"
    t.string  "share_code"
    t.integer "parent_id"
    t.integer "lft"
    t.integer "rgt"
    t.text    "meta"
  end

  create_table "stream_jobs", :force => true do |t|
    t.integer "video_id"
    t.string  "master_playlist"
    t.string  "state",           :default => "in_progress", :null => false
    t.string  "job_id"
  end

  add_index "stream_jobs", ["job_id"], :name => "index_stream_jobs_on_job_id"
  add_index "stream_jobs", ["video_id"], :name => "index_stream_jobs_on_video_id"

  create_table "users", :force => true do |t|
    t.string   "email"
    t.string   "name"
    t.string   "phone"
    t.string   "phone_normalized"
    t.string   "password_digest"
    t.datetime "created_at",                      :null => false
    t.datetime "updated_at",                      :null => false
    t.string   "access_token"
    t.string   "device_token"
    t.string   "verification_code", :limit => 60
    t.string   "username"
    t.string   "last_app_version"
    t.string   "phone_hashed"
    t.text     "muted"
    t.datetime "last_active_at"
  end

  add_index "users", ["access_token"], :name => "index_users_on_access_token", :unique => true
  add_index "users", ["device_token"], :name => "index_users_on_device_token"
  add_index "users", ["email"], :name => "index_users_on_email"
  add_index "users", ["phone_hashed"], :name => "index_users_on_phone_hashed"
  add_index "users", ["phone_normalized"], :name => "index_users_on_phone_normalized"
  add_index "users", ["username"], :name => "index_users_on_username", :unique => true

# Could not dump table "videos" because of following StandardError
#   Unknown type 'hstore' for column 'stitch_request'

  create_table "waitlisters", :force => true do |t|
    t.string   "email"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.string   "phone"
  end

  add_index "waitlisters", ["email"], :name => "index_waitlisters_on_email"

end
