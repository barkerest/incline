class AddVisibleToActionSecurity < ActiveRecord::Migration
  def change
    add_column :incline_action_securities, :visible, :boolean
  end
end
