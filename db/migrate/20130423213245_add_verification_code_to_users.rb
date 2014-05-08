class AddVerificationCodeToUsers < ActiveRecord::Migration
  def change
    change_table :users do |t|
      t.column :verification_code, :string, :limit => 60
    end
  end
end
