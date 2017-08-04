class CreateInclineUserLoginHistories < ActiveRecord::Migration
  def change
    create_table :incline_user_login_histories do |t|
      t.belongs_to  :user,          null: false,                  index: true
      t.string      :ip_address,    null: false,    limit: 64
      t.boolean     :successful
      t.string      :message,                       limit: 200

      t.timestamps                  null: false
    end
    add_foreign_key :incline_user_login_histories, :incline_users, column: :user_id, name: 'fk_i_user_login_hist_user'
  end
end
