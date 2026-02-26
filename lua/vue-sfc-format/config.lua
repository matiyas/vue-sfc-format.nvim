local M = {}

local defaults = {
  config_file = ".vue-sfc-format.json",
  indent = 2,
  temp_dir = "/tmp",
}

M.options = vim.deepcopy(defaults)

local function find_config_file()
  local cwd = vim.fn.getcwd()
  local config_path = cwd .. "/" .. M.options.config_file
  if vim.fn.filereadable(config_path) ~= 1 then return nil end

  return config_path
end

function M.load_formatters()
  local config_path = find_config_file()
  if not config_path then return nil, "Config file not found: " .. M.options.config_file end

  local file = io.open(config_path, "r")
  if not file then return nil, "Cannot open config file: " .. config_path end

  local content = file:read("*a")
  file:close()

  local ok, config = pcall(vim.json.decode, content)
  if not ok then return nil, "Invalid JSON in config file: " .. config_path end

  return config, nil
end

function M.get_formatter(section_type, attrs)
  local config, err = M.load_formatters()
  if not config then return nil, err end

  if section_type == "style" and attrs and attrs:find("scss") then section_type = "style_scss" end

  local formatter = config.formatters and config.formatters[section_type]
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
