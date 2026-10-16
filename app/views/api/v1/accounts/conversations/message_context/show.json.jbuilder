json.meta do
  json.has_more_before @has_more_before
  json.has_more_after @has_more_after
end
json.payload do
  json.target_message_id @target.id
  json.messages do
    json.array! @messages do |message|
      json.partial! 'api/v1/models/message', message: message
    end
  end
end
