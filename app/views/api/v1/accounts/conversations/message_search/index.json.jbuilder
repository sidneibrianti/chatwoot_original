json.meta @meta
json.payload do
  json.messages do
    json.array! @messages do |message|
      json.partial! 'api/v1/models/message', message: message
    end
  end
end
