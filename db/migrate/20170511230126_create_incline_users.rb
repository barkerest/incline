class CreateInclineUsers < ActiveRecord::Migration
  def change
    create_table :incline_users do |t|
      t.string    :name,              null: false,    limit: 100
      t.string    :email,             null: false,    limit: 250
      t.boolean   :activated,         null: false,                    default: false
      t.boolean   :enabled,           null: false,                    default: true
      t.boolean   :system_admin,      null: false,                    default: false
      t.string    :activation_digest,                 limit: 100
      t.string    :password_digest,                   limit: 100
      t.string    :remember_digest,                   limit: 100
      t.string    :reset_digest,                      limit: 100
      t.datetime  :activated_at
      t.datetime  :reset_sent_at
      t.string    :disabled_by,                       limit: 250
      t.datetime  :disabled_at
      t.string    :disabled_reason,                   limit: 200
      t.datetime  :last_login_at
      t.string    :last_login_ip,                     limit: 64

      t.timestamps                    null: false
    end
    add_index :incline_users, :email, unique: true, name: 'ux_incline_users_email'
  end
end

