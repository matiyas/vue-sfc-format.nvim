local config = require("vue-sfc-format.config")
local parser = require("vue-sfc-format.parser")

local M = {}

--- Writes content to a temp file and returns the path.
--- @param content string Content to write
--- @param suffix string Temp file suffix
--- @return string Temp file path
local function write_temp_file(content, suffix)
  local tmp_file = string.format("%s/vue-sfc-format-%d-%s", config.get_option("temp_dir"), os.time(), suffix)
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

--- Resolves command path, falling back from local to global.
--- @param cmd string Command (may be ./node_modules/.bin/xxx)
--- @return string Resolved command path
local function resolve_cmd(cmd)
  if cmd:match("^%./node_modules/") then
    local f = io.open(cmd, "r")
    if f then
      f:close()
      return cmd
    end
    return cmd:match("([^/]+)$")
  end
  return cmd
end

--- Formats content using a command with temp file.
--- @param content string Content to format
--- @param formatter table Formatter config with cmd and args
--- @param suffix string Temp file suffix
--- @return string Formatted content
function M.format_with_temp_file(content, formatter, suffix)
  local tmp_file = write_temp_file(content, suffix)
  local args_str = table.concat(formatter.args, " ")
  local resolved_cmd = resolve_cmd(formatter.cmd)
  local cmd = string.format("%s %s %s 2>&1", resolved_cmd, args_str, tmp_file)

  local ok, result = pcall(function()
    return exec(cmd)
  end)

  os.remove(tmp_file)
  if not ok then return nil, result end

  local trimmed = result:gsub("%s+$", "")
  if trimmed == "" or trimmed:match("^[Cc]ommand not found") or trimmed:match("^sh:") or trimmed:match("not found") then
    return nil, "Formatter not found: " .. resolved_cmd .. " (output: " .. trimmed .. ")"
  end

  return trimmed, nil
end

--- Formats a single section of the Vue SFC.
--- @param section_type string Section type (template, script, style)
--- @param content string Section content
--- @param attrs string Section attributes
--- @return string|nil Formatted content
--- @return string|nil Error message
--- Removes space before /> in self-closing tags.
--- js-beautify adds space before /> but we want to match the original format.
--- @param html string HTML content
--- @return string HTML with space removed before />
local function remove_space_before_self_close(html)
  return html:gsub(" />", "/>")
end

function M.format_section(section_type, content, attrs)
  local formatter, err = config.get_formatter(section_type, attrs)
  if not formatter then return nil, err end

  local trimmed = content:match("^%s*(.-)%s*$")
  local formatted, fmt_err = M.format_with_temp_file(trimmed, formatter, section_type)
  if fmt_err then return nil, fmt_err end

  if section_type == "template" and config.get_option("remove_space_before_self_close") then
    formatted = remove_space_before_self_close(formatted)
  end

  local indent_key = "indent_" .. section_type
  local indent_value = config.get_option(indent_key)
  if indent_value == nil then indent_value = config.get_option("indent") end

  if indent_value and indent_value > 0 then formatted = parser.indent(formatted, indent_value) end

  return formatted, nil
end

--- Prepares a section for parallel formatting.
--- @param section table Section with content and attrs
--- @param section_type string Section type
--- @return table|nil Job info with input_file, output_file, cmd, section_type, attrs
--- @return string|nil Error message
local function prepare_format_job(section, section_type)
  local formatter, err = config.get_formatter(section_type, section.attrs)
  if not formatter then return nil, err end

  local trimmed = section.content:match("^%s*(.-)%s*$")
  local temp_dir = config.get_option("temp_dir")
  local timestamp = os.time()
  local input_file = string.format("%s/vue-sfc-format-%d-%s-in", temp_dir, timestamp, section_type)
  local output_file = string.format("%s/vue-sfc-format-%d-%s-out", temp_dir, timestamp, section_type)

  local f = io.open(input_file, "w")
  if not f then return nil, "Failed to create temp file: " .. input_file end
  f:write(trimmed)
  f:close()

  local resolved_cmd = resolve_cmd(formatter.cmd)
  local args_str = table.concat(formatter.args, " ")

  return {
    input_file = input_file,
    output_file = output_file,
    cmd = string.format("%s %s %s > %s 2>&1", resolved_cmd, args_str, input_file, output_file),
    section_type = section_type,
    attrs = section.attrs,
    resolved_cmd = resolved_cmd,
  },
    nil
end

--- Reads and processes the output of a format job.
--- @param job table Job info
--- @return string|nil Formatted content
--- @return string|nil Error message
local function read_format_result(job)
  local f = io.open(job.output_file, "r")
  if not f then return nil, "Failed to read output file: " .. job.output_file end

  local result = f:read("*a")
  f:close()
  os.remove(job.input_file)
  os.remove(job.output_file)

  local trimmed = result:gsub("%s+$", "")
  if trimmed == "" or trimmed:match("^[Cc]ommand not found") or trimmed:match("^sh:") or trimmed:match("not found") then
    return nil, "Formatter not found: " .. job.resolved_cmd .. " (output: " .. trimmed .. ")"
  end

  if job.section_type == "template" and config.get_option("remove_space_before_self_close") then
    trimmed = remove_space_before_self_close(trimmed)
  end

  local indent_key = "indent_" .. job.section_type
  local indent_value = config.get_option(indent_key)
  if indent_value == nil then indent_value = config.get_option("indent") end
  if indent_value and indent_value > 0 then trimmed = parser.indent(trimmed, indent_value) end

  return trimmed, nil
end

--- Formats a complete Vue SFC file with parallel execution.
--- @param content string Raw Vue SFC content
--- @return string|nil Formatted Vue SFC
--- @return string|nil Error message
function M.format_vue(content)
  local template = parser.extract_section(content, "template")
  local script = parser.extract_section(content, "script")
  local style = parser.extract_section(content, "style")

  local jobs = {}
  local section_order = { "template", "script", "style" }
  local section_data = { template = template, script = script, style = style }

  for _, section_type in ipairs(section_order) do
    local section = section_data[section_type]
    if section then
      local job, err = prepare_format_job(section, section_type)
      if err then return nil, err end
      jobs[section_type] = job
    end
  end

  if not next(jobs) then return content, nil end

  local cmds = {}
  for _, section_type in ipairs(section_order) do
    if jobs[section_type] then table.insert(cmds, "(" .. jobs[section_type].cmd .. ")") end
  end

  local parallel_cmd = table.concat(cmds, " & ") .. " & wait"
  os.execute(parallel_cmd)

  local sections = {}
  for _, section_type in ipairs(section_order) do
    local job = jobs[section_type]
    if job then
      local formatted, err = read_format_result(job)
      if err then return nil, err end
      table.insert(sections, parser.wrap_section(section_type, job.attrs, formatted))
    end
  end

  return table.concat(sections, "\n"), nil
end

return M
