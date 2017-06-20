unless user.new_record?
  json.set! 'DT_RowId', "user_#{user.id}"
  json.set! 'DT_Path', user_path(user)
  if user.destroyed?
    json.set! 'DT_RowAction', 'remove'
  end
  if user.enabled?
    if user.failed_login_streak.count > 5
      json.set! 'DT_RowClass', 'cell-danger'
    else
      unless user.activated?
        json.set! 'DT_RowClass', 'cell-info'
      end
    end
  else
    json.set! 'DT_RowClass', 'cell-warning'
  end
end
json.set! 'name', h(user.name)
json.set! 'email', h(user.email)
json.set! 'created_at', user.created_at
json.set! 'updated_at', user.updated_at
json.set! 'activated', user.activated?
json.set! 'system_admin', user.system_admin?
json.set! 'enabled', user.enabled?
json.set! 'comments', h(user.comments).gsub("\n", "<br>\n")
json.set! 'show_edit', current_user?(user) || system_admin?
json.set! 'show_disable', !current_user?(user) && system_admin? && user.enabled?
json.set! 'show_enable', !current_user?(user) && system_admin? && !user.enabled?
json.set! 'show_delete', !current_user?(user) && system_admin? && !user.enabled? && user.disabled_at < 7.days.ago
json.set! 'show_promote', !current_user?(user) && system_admin? && !user.system_admin?
json.set! 'show_demote', !current_user?(user) && system_admin? && user.system_admin?
