if @dt_request&.provided?
  json.set! 'draw', @dt_request.draw
  json.set! 'recordsTotal', @dt_request.records_total
  json.set! 'recordsFiltered', @dt_request.records_filtered
  json.data do
    json.array!(@dt_request.records) do |access_group|
      json.partial! 'details', locals: { access_group: access_group }
    end
  end
  if @dt_request.error?
    json.set! 'error', @dt_request.error
  end
else
  json.set! 'error', 'No data tables request received.'
end
json.set! 'appInfo', h(Rails.application.app_info)
