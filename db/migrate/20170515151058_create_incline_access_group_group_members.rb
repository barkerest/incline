class CreateInclineAccessGroupGroupMembers < ActiveRecord::Migration
  def change
    create_table :incline_access_group_group_members do |t|
      t.integer   :group_id,    null: false,    index: true
      t.integer   :member_id,   null: false,    index: true

      t.timestamps null: false
    end
    add_index :incline_access_group_group_members, [ :group_id, :member_id ], unique: true, name: 'ux_incline_access_group_group_members'
  end
end
