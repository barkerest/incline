json.messages do
  json.array! flash.discard do |type,message|
    json.set! 'type', type
    json.set! 'text', message
  end
end

if @<%= singular_table_name %>.errors.any?
  json.api_errors! '<%= singular_table_name %>', @<%= singular_table_name %>.errors
else
  json.data do
    json.array! [ @<%= singular_table_name %> ] do |<%= singular_table_name %>|
      json.partial! 'details', locals: { <%= singular_table_name %>: <%= singular_table_name %> }
    end
  end
end
