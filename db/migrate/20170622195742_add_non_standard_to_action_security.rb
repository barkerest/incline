class AddNonStandardToActionSecurity < ActiveRecord::Migration
  def change
    add_column :incline_action_securities, :non_standard, :boolean
  end
end
