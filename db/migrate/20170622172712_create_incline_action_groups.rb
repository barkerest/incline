class CreateInclineActionGroups < ActiveRecord::Migration
  def change
    create_table :incline_action_groups do |t|
      t.belongs_to  :action_security, null: false,  index: true
      t.belongs_to  :access_group,    null: false,  index: true

      t.timestamps null: false
    end
    add_index :incline_action_groups, [ :action_security_id, :access_group_id ], unique: true, name: 'ux_incline_action_groups'
    add_foreign_key :incline_action_groups, :incline_action_securities, column: :action_security_id, name: 'fk_i_action_groups_security'
    add_foreign_key :incline_action_groups, :incline_access_groups, column: :access_group_id, name: 'fk_i_action_groups_group'
  end
end
