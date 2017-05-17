class AddCommentsToUser < ActiveRecord::Migration
  def change
    add_column :incline_users, :comments, :text
  end
end
