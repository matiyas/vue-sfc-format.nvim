-- Minimal JSON decoder for tests
local M = {}

function M.decode(str)
  -- Use Lua 5.1 compatible JSON parsing
  -- This is a simplified implementation for test purposes
  local value = str:gsub('"%s*:%s*"', "="):gsub('"%s*:%s*%[', "={"):gsub("%]", "}")
  -- Convert JSON to Lua table syntax
  str = str:gsub('"([^"]+)"%s*:', '["%1"]=')
  str = str:gsub("%[", "{")
  str = str:gsub("%]", "}")

  local fn = loadstring("return " .. str)
  if fn then return fn() end

  return nil
end

return M
