local function lookup(pack, key)
  local value = pack
  for part in key:gmatch('[^.]+') do
    if type(value) ~= 'table' then return nil end
    value = value[part]
  end
  return value
end

function L(key, ...)
  local text = lookup(Locales[Config.Locale] or Locales.en, key) or lookup(Locales.en, key) or key
  if select('#', ...) > 0 then return text:format(...) end
  return text
end
