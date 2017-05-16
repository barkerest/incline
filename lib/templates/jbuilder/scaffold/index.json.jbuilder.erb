if @dt_request&.provided?
  json.set! 'draw', @dt_request.draw
  json.set! 'recordsTotal', @dt_request.records_total
  json.set! 'recordsFiltered', @dt_request.records_filtered
  json.data do
    json.array!(@dt_request.records) do |<%= singular_table_name %>|
      json.partial! 'details', locals: { <%= singular_table_name %>: <%= singular_table_name %> }
    end
  end
  if @dt_request.error?
    json.set! 'error', @dt_request.error
  end
else
  json.set! 'error', 'No data tables request received.'
end
json.set! 'appInfo', h(Rails.application.app_info)
