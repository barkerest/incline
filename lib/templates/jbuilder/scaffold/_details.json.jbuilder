unless <%= singular_table_name %>.new_record?
  json.set! 'DT_RowId', "<%= singular_table_name %>_#{<%= singular_table_name %>.id}"
  json.set! 'DT_Path', <%= singular_table_name %>_path(<%= singular_table_name %>)
  if <%= singular_table_name %>.destroyed?
    json.set! 'DT_RowAction', 'remove'
  end
end
<%- attributes.reject(&:password_digest?).each do |attribute| -%>
  <%- if attribute.type == :references -%>
json.set! '<%= attribute.name %>', h(<%= singular_table_name %>.<%= attribute.name %>.to_s)
  <%- elsif attribute.type == :datetime || attribute.type == :time -%>
json.set! '<%= attribute.name %>', <%= singular_table_name %>.<%= attribute.name %>&.utc&.strftime('%m/%d/%Y %H:%M:%S')
  <%- elsif attribute.type == :date -%>
json.set! '<%= attribute.name %>', <%= singular_table_name %>.<%= attribute.name %>&.strftime('%m/%d/%Y')
  <%- elsif attribute.type == :string || attribute.type == :text -%>
json.set! '<%= attribute.name %>', h(<%= singular_table_name %>.<%= attribute.name %>)
  <%- else -%>
json.set! '<%= attribute.name %>', <%= singular_table_name %>.<%= attribute.name %>
  <%- end -%>
<%- end -%>
