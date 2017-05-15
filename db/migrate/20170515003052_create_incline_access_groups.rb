class CreateInclineAccessGroups < ActiveRecord::Migration
  def change
    create_table :incline_access_groups do |t|
      t.string    :name,      null: false,    limit: 100

      t.timestamps            null: false
    end
    add_index :incline_access_groups, :name, unique: true, name: 'ux_incline_access_groups_name'
  end
end
