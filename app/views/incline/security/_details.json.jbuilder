json.set! 'DT_RowId',         "security_#{security.id}"
json.set! 'DT_Path',          security_path(security)
json.set! 'path',             h(security.path)
json.set! 'controller_name',  h(security.controller_name)
json.set! 'action_name',      h(security.action_name)
json.set! 'short_permitted',        h(security.short_permitted)
json.set! 'updated_at',       security.updated_at
