local config = require("vue-sfc-format.config")
local formatter = require("vue-sfc-format.formatter")

local M = {}

--- Setup the plugin with user options.
--- @param opts table|nil User configuration options
function M.setup(opts)
  config.setup(opts)

  vim.api.nvim_create_user_command("VueSfcFormat", function()
    M.format()
  end, { desc = "Format Vue SFC file" })
end

--- Format the current buffer.
--- @param bufnr number|nil Buffer number (defaults to current buffer)
function M.format(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  local filetype = vim.bo[bufnr].filetype
  if filetype ~= "vue" then
    vim.notify("VueSfcFormat: Not a Vue file", vim.log.levels.WARN)
    return
  end

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local content = table.concat(lines, "\n")

  local formatted, err = formatter.format_vue(content)
  if err then
    vim.notify("VueSfcFormat: " .. err, vim.log.levels.ERROR)
    return
  end

  local new_lines = vim.split(formatted, "\n")
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, new_lines)
end

--- Format stdin and write to stdout (for use with formatter.nvim).
function M.format_stdin()
  local content = io.read("*a")

  local formatted, err = formatter.format_vue(content)
  if err then
    io.stderr:write("VueSfcFormat: " .. err .. "\n")
    os.exit(1)
  end

  io.write(formatted)
end

--- Returns configuration for formatter.nvim integration.
--- @return table Configuration table for formatter.nvim
function M.formatter_nvim_config()
  return {
    exe = "nvim",
    args = {
      "--headless",
      "--noplugin",
      "-u",
      "NONE",
      "+lua package.path = package.path .. ';"
        .. vim.fn.stdpath("data")
        .. "/lazy/vue-sfc-format.nvim/lua/?.lua;"
        .. vim.fn.stdpath("data")
        .. "/lazy/vue-sfc-format.nvim/lua/?/init.lua'",
      "+lua require('vue-sfc-format').format_stdin()",
      "+qa!",
    },
    stdin = true,
  }
end

return M
