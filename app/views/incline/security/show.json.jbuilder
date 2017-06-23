json.partial! 'messages'

if @security.errors.any?
  json.api_errors! 'security', @security.errors
else
  json.data do
    json.array! [ @security ] do |security|
      json.partial! 'details', locals: { security: security }
    end
  end
end
