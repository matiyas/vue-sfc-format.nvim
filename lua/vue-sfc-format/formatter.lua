local config = require("vue-sfc-format.config")
local parser = require("vue-sfc-format.parser")

local M = {}

--- Writes content to a temp file and returns the path.
--- @param content string Content to write
--- @param suffix string Temp file suffix
--- @return string Temp file path
local function write_temp_file(content, suffix)
  local tmp_file = string.format("%s/vue-sfc-format-%d-%s", config.options.temp_dir, os.time(), suffix)
  local f = io.open(tmp_file, "w")
  if not f then error("Failed to create temp file: " .. tmp_file) end

  f:write(content)
  f:close()

  return tmp_file
end

--- Executes a command and returns its output.
--- @param cmd string Command to execute
--- @return string Command output
local function exec(cmd)
  local handle = io.popen(cmd)
  if not handle then error("Failed to execute: " .. cmd) end

  local result = handle:read("*a")
  handle:close()

  return result
end

--- Formats content using a command with temp file.
--- @param content string Content to format
--- @param formatter table Formatter config with cmd and args
--- @param suffix string Temp file suffix
--- @return string Formatted content
function M.format_with_temp_file(content, formatter, suffix)
  local tmp_file = write_temp_file(content, suffix)
  local args_str = table.concat(formatter.args, " ")
  local cmd = string.format("%s %s %s 2>/dev/null", formatter.cmd, args_str, tmp_file)

  local ok, result = pcall(function()
    return exec(cmd)
  end)

  os.remove(tmp_file)
  if not ok then error(result) end

  return result:gsub("%s+$", "")
end

--- Formats a single section of the Vue SFC.
--- @param section_type string Section type (template, script, style)
--- @param content string Section content
--- @param attrs string Section attributes
--- @return string|nil Formatted content
--- @return string|nil Error message
function M.format_section(section_type, content, attrs)
  local formatter, err = config.get_formatter(section_type, attrs)
  if not formatter then return nil, err end

  local trimmed = content:match("^%s*(.-)%s*$")
  local formatted = M.format_with_temp_file(trimmed, formatter, section_type)

  if section_type == "template" then formatted = parser.indent(formatted, config.options.indent) end

  return formatted, nil
end

--- Formats a complete Vue SFC file.
--- @param content string Raw Vue SFC content
--- @return string|nil Formatted Vue SFC
--- @return string|nil Error message
function M.format_vue(content)
  local sections = {}

  local template = parser.extract_section(content, "template")
  if template then
    local formatted, err = M.format_section("template", template.content, template.attrs)
    if err then return nil, err end

    table.insert(sections, parser.wrap_section("template", template.attrs, formatted))
  end

  local script = parser.extract_section(content, "script")
  if script then
    local formatted, err = M.format_section("script", script.content, script.attrs)
    if err then return nil, err end

    table.insert(sections, parser.wrap_section("script", script.attrs, formatted))
  end

  local style = parser.extract_section(content, "style")
  if style then
    local formatted, err = M.format_section("style", style.content, style.attrs)
    if err then return nil, err end

    table.insert(sections, parser.wrap_section("style", style.attrs, formatted))
  end

  return table.concat(sections, "\n"), nil
end

return M
