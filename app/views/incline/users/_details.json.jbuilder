unless user.new_record?
  json.set! 'DT_RowId', "user_#{user.id}"
  json.set! 'DT_path', user_path(user)
end
json.set! 'name', h(user.name)
json.set! 'email', h(user.email)
json.set! 'created_at', user.created_at
json.set! 'updated_at', user.updated_at
json.set! 'activated', user.activated?
json.set! 'system_admin', user.system_admin?
json.set! 'enabled', user.enabled?
json.set! 'comments', h(user.comments).gsub("\n", "<br>\n")
