defined?(@entities) && json.entities do
  if resources.present?
    json.partial! 'bitia/api/resources'
  else
    json.partial! 'bitia/api/resource'
  end
end
json.merge!(metadata: @metadata) if defined?(@metadata)
json.merge!(payload: @payload) if defined?(@payload)
