class CreatePledgers < ActiveRecord::Migration
  def up
    create_table :pledgers do |t|
      t.string  :name
      t.string  :username
      t.string  :auth_token
      t.string  :auth_secret
      t.string  :share_code

      # awesome nested set
      t.integer :parent_id
      t.integer :lft
      t.integer :rgt

      t.text    :meta
    end
  end
end
