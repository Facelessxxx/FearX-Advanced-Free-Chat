function IsResourceCommand(command)
  local name, resource = command.name, command.resource
  if type(name) ~= 'string' or name == '' or name:find('^[_%+%-]') then return false end
  return type(resource) == 'string' and resource ~= '' and GetResourceState(resource) == 'started'
end

function TruncateText(text, maxLength)
  if not utf8.len(text) then return nil end
  local cut = utf8.offset(text, maxLength + 1)
  return cut and text:sub(1, cut - 1) or text
end
