class CreateInclineActionSecurities < ActiveRecord::Migration
  def change
    create_table :incline_action_securities do |t|
      t.string    :controller_name,       null: false,    limit: 200
      t.string    :action_name,           null: false,    limit: 200
      t.text      :path,                  null: false
      t.boolean   :allow_anon
      t.boolean   :require_anon
      t.boolean   :require_admin
      t.boolean   :unknown_controller

      t.timestamps null: false
    end
    add_index :incline_action_securities, [:controller_name, :action_name ], unique: true, name: 'ux_incline_action_securities'
  end
end
