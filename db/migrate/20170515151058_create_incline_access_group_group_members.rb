class CreateInclineAccessGroupGroupMembers < ActiveRecord::Migration
  def change
    create_table :incline_access_group_group_members do |t|
      t.integer   :group_id,    null: false,    index: true
      t.integer   :member_id,   null: false,    index: true

      t.timestamps null: false
    end
    add_index :incline_access_group_group_members, [ :group_id, :member_id ], unique: true, name: 'ux_incline_access_group_group_members'
    add_foreign_key :incline_access_group_group_members, :incline_access_groups, column: :group_id, name: 'fk_i_access_group_groups_group'
    add_foreign_key :incline_access_group_group_members, :incline_access_groups, column: :member_id, name: 'fk_i_access_group_groups_member'
  end
end
