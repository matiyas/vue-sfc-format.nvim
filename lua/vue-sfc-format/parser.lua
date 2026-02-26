local M = {}

--- Finds the position of the next opening tag for the given tag name.
--- @param content string Content to search in
--- @param tag_name string Tag name to find
--- @param start_pos number Position to start searching from
--- @return number|nil Position of next opening tag, or nil if not found
function M.find_next_open_tag(content, tag_name, start_pos)
  local pattern = "<" .. tag_name .. "[%s>]"
  local pos = content:lower():find(pattern, start_pos)

  return pos
end

--- Finds the position of the next closing tag for the given tag name.
--- @param content string Content to search in
--- @param tag_name string Tag name to find
--- @param start_pos number Position to start searching from
--- @return number|nil Position of next closing tag, or nil if not found
function M.find_next_close_tag(content, tag_name, start_pos)
  local close_tag = "</" .. tag_name .. ">"
  local pos = content:lower():find(close_tag, start_pos, true)

  return pos
end

--- Finds the matching closing tag position using depth counting.
--- Handles nested tags like <template v-if> inside <template>.
--- @param content string Full content
--- @param tag_name string Tag name to match
--- @param start_index number Position after opening tag
--- @return number|nil Position of matching closing tag, or nil if not found
function M.find_matching_close_tag(content, tag_name, start_index)
  local close_tag_len = #("</" .. tag_name .. ">")
  local depth = 1
  local i = start_index

  while i <= #content and depth > 0 do
    local next_open = M.find_next_open_tag(content, tag_name, i)
    local next_close = M.find_next_close_tag(content, tag_name, i)
    if not next_close then return nil end

    if next_open and next_open < next_close then
      depth = depth + 1
      i = next_open + 1
    else
      depth = depth - 1
      if depth == 0 then return next_close end

      i = next_close + close_tag_len
    end
  end

  return nil
end

--- Extracts a section from Vue SFC content with proper nested tag handling.
--- @param content string Full Vue SFC content
--- @param tag_name string Section tag name (template, script, style)
--- @return table|nil Table with attrs and content, or nil if not found
function M.extract_section(content, tag_name)
  -- Find opening tag (case-insensitive)
  local lower_content = content:lower()
  local open_pattern = "<" .. tag_name .. "[%s>]"
  local tag_start = lower_content:find(open_pattern)
  if not tag_start then return nil end

  -- Find end of opening tag
  local tag_end = content:find(">", tag_start)
  if not tag_end then return nil end

  -- Extract attributes (everything between tag name and >)
  local attrs = ""
  local attr_start = tag_start + #tag_name + 1
  if attr_start < tag_end then attrs = content:sub(attr_start, tag_end - 1) end

  local content_start = tag_end + 1
  local close_pos = M.find_matching_close_tag(content, tag_name, content_start)
  if not close_pos then return nil end

  return {
    attrs = attrs,
    content = content:sub(content_start, close_pos - 1),
  }
end

--- Wraps content in a Vue SFC section tag.
--- @param tag_name string Tag name
--- @param attrs string Tag attributes
--- @param content string Tag content
--- @return string Wrapped section
function M.wrap_section(tag_name, attrs, content)
  return string.format("<%s%s>\n%s\n</%s>\n", tag_name, attrs, content, tag_name)
end

--- Adds indentation to each non-empty line.
--- @param text string Text to indent
--- @param spaces number Number of spaces (default 2)
--- @return string Indented text
function M.indent(text, spaces)
  spaces = spaces or 2
  local pad = string.rep(" ", spaces)
  local lines = {}

  for line in (text .. "\n"):gmatch("([^\n]*)\n") do
    if #line > 0 then
      table.insert(lines, pad .. line)
    else
      table.insert(lines, line)
    end
  end

  return table.concat(lines, "\n")
end

return M
