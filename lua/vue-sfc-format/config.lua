local M = {}

local default_formatters = {
  template = {
    cmd = "npx",
    args = {
      "js-beautify",
      "--type",
      "html",
      "--indent-size",
      "2",
      "--wrap-attributes",
      "force-aligned",
      "--wrap-line-length",
      "120",
      "--indent-inner-html",
      "--preserve-newlines",
      "--max-preserve-newlines",
      "2",
    },
  },
  script = {
    cmd = "npx",
    args = {
      "prettier",
      "--parser",
      "babel",
      "--semi",
      "false",
      "--single-quote",
      "--trailing-comma",
      "none",
      "--tab-width",
      "2",
      "--print-width",
      "120",
      "--arrow-parens",
      "avoid",
      "--quote-props",
      "preserve",
    },
  },
  style = {
    cmd = "npx",
    args = {
      "prettier",
      "--parser",
      "css",
      "--single-quote",
      "--tab-width",
      "2",
      "--print-width",
      "120",
    },
  },
  style_scss = {
    cmd = "npx",
    args = {
      "prettier",
      "--parser",
      "scss",
      "--single-quote",
      "--tab-width",
      "2",
      "--print-width",
      "120",
    },
  },
}

local defaults = {
  config_file = ".vue-sfc-format.json",
  formatters = default_formatters,
  indent = 2,
  indent_template = 2,
  indent_script = 2,
  indent_style = 2,
  temp_dir = "/tmp",
  remove_space_before_self_close = false,
}

M.options = vim.deepcopy(defaults)

local function find_config_file()
  local cwd = vim.fn.getcwd()
  local config_path = cwd .. "/" .. M.options.config_file
  if vim.fn.filereadable(config_path) ~= 1 then return nil end

  return config_path
end

local function load_config_file()
  local config_path = find_config_file()
  if not config_path then return nil end

  local file = io.open(config_path, "r")
  if not file then return nil end

  local content = file:read("*a")
  file:close()

  local ok, config = pcall(vim.json.decode, content)
  if not ok then return nil end

  return config
end

function M.get_option(key)
  local file_config = load_config_file()
  if file_config and file_config[key] ~= nil then return file_config[key] end

  return M.options[key]
end

function M.get_formatter(section_type, attrs)
  if section_type == "style" and attrs and attrs:find("scss") then section_type = "style_scss" end

  -- Try config file first, fall back to defaults
  local file_config = load_config_file()
  if file_config and file_config.formatters and file_config.formatters[section_type] then
    return file_config.formatters[section_type], nil
  end

  local formatter = M.options.formatters and M.options.formatters[section_type]
  if not formatter then return nil, "No formatter configured for section: " .. section_type end

  return formatter, nil
end

function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})
end

function M.get_defaults()
  return vim.deepcopy(defaults)
end

return M
