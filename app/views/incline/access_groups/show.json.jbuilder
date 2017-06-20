json.partial! 'messages'

if @access_group.errors.any?
  json.api_errors! 'access_group', @access_group.errors
else
  json.data do
    json.array! [ @access_group ] do |access_group|
      json.partial! 'details', locals: { access_group: access_group }
    end
  end
end
