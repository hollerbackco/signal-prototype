class AddLastAppVersionToUsers < ActiveRecord::Migration
  def change
    change_table :users do |t|
      t.string :last_app_version
    end
  end
end
