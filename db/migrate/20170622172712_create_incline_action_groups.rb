class CreateInclineActionGroups < ActiveRecord::Migration
  def change
    create_table :incline_action_groups do |t|
      t.belongs_to  :action_security, null: false,  index: true, foreign_key: true
      t.belongs_to  :access_group,    null: false,  index: true, foreign_key: true

      t.timestamps null: false
    end
    add_index :incline_action_groups, [ :action_security_id, :access_group_id ], unique: true, name: 'ux_incline_action_groups'
  end
end
