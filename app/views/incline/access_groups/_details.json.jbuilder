unless access_group.new_record?
  json.set! 'DT_RowId', "access_group_#{access_group.id}"
  json.set! 'DT_Path', access_group_path(access_group)
  if access_group.destroyed?
    json.set! 'DT_RowAction', 'remove'
  end
end
json.set! 'name', h(access_group.name)
json.set! 'created_at', access_group.created_at
json.set! 'updated_at', access_group.updated_at
