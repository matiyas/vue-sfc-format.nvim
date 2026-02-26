package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

describe("vue-sfc-format integration", function()
  local plugin

  setup(function()
    _G.vim = _G.vim or {}
    _G.vim.fn = _G.vim.fn or {}
    _G.vim.api = _G.vim.api or {}
    _G.vim.bo = _G.vim.bo or {}
    _G.vim.g = _G.vim.g or {}
    _G.vim.log = { levels = { INFO = 1, WARN = 2, ERROR = 3 } }
    _G.vim.notify = function() end
    _G.vim.fn.getcwd = function()
      return os.getenv("PWD") or "/tmp"
    end
    _G.vim.fn.filereadable = function(path)
      local f = io.open(path, "r")
      if f then
        f:close()
        return 1
      end
      return 0
    end
    _G.vim.fn.stdpath = function()
      return "/tmp"
    end
    _G.vim.deepcopy = function(t)
      if type(t) ~= "table" then return t end

      local copy = {}
      for k, v in pairs(t) do
        copy[k] = _G.vim.deepcopy(v)
      end
      return copy
    end
    _G.vim.tbl_deep_extend = function(behavior, ...)
      local result = {}
      for _, t in ipairs({ ... }) do
        if t then
          for k, v in pairs(t) do
            result[k] = _G.vim.deepcopy(v)
          end
        end
      end
      return result
    end
    _G.vim.api.nvim_create_user_command = function() end
    _G.vim.split = function(str, sep)
      local result = {}
      for part in str:gmatch("[^" .. sep .. "]+") do
        table.insert(result, part)
      end
      return result
    end

    plugin = require("vue-sfc-format")
  end)

  describe("module exports", function()
    it("exports setup function", function()
      assert.is_function(plugin.setup)
    end)

    it("exports format function", function()
      assert.is_function(plugin.format)
    end)

    it("exports format_stdin function", function()
      assert.is_function(plugin.format_stdin)
    end)

    it("exports formatter_nvim_config function", function()
      assert.is_function(plugin.formatter_nvim_config)
    end)
  end)

  describe("setup", function()
    it("accepts nil options", function()
      assert.has_no.errors(function()
        plugin.setup()
      end)
    end)

    it("accepts empty options table", function()
      assert.has_no.errors(function()
        plugin.setup({})
      end)
    end)

    it("accepts custom options", function()
      assert.has_no.errors(function()
        plugin.setup({
          indent = 4,
          temp_dir = "/var/tmp",
        })
      end)
    end)
  end)

  describe("formatter_nvim_config", function()
    it("returns table with exe", function()
      local config = plugin.formatter_nvim_config()

      assert.is_table(config)
      assert.equals("nvim", config.exe)
    end)

    it("returns table with args", function()
      local config = plugin.formatter_nvim_config()

      assert.is_table(config.args)
      assert.is_true(#config.args > 0)
    end)

    it("enables stdin", function()
      local config = plugin.formatter_nvim_config()

      assert.is_true(config.stdin)
    end)
  end)
end)
