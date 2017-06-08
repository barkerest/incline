json.messages do
  json.array! flash.discard do |type,message|
    json.set! 'type', type
    json.set! 'text', message
  end
end
