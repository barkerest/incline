class CreateInclineAccessGroupUserMembers < ActiveRecord::Migration
  def change
    create_table :incline_access_group_user_members do |t|
      t.integer   :group_id,      null: false,    index: true
      t.integer   :member_id,     null: false,    index: true

      t.timestamps null: false
    end
    add_index :incline_access_group_user_members, [ :group_id, :member_id ], unique: true, name: 'ux_incline_access_group_user_members'
  end
end
