while true do
  local event, key, is_held = os.pullEvent("key")
  print(("%s held=%s"):format(keys.getName(key), is_held))
end