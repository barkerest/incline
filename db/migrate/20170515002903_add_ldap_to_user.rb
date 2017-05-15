class AddLdapToUser < ActiveRecord::Migration
  def change
    add_column :incline_users, :ldap, :boolean
  end
end
