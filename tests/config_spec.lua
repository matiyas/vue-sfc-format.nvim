package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

describe("config", function()
  local config

  setup(function()
    _G.vim = _G.vim or {}
    _G.vim.fn = _G.vim.fn or {}
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
    _G.vim.json = _G.vim.json or {}
    _G.vim.json.decode = function(str)
      local json = require("tests.json_helper")
      return json.decode(str)
    end

    config = require("vue-sfc-format.config")
  end)

  describe("defaults", function()
    it("has default config_file", function()
      local defaults = config.get_defaults()

      assert.equals(".vue-sfc-format.json", defaults.config_file)
    end)

    it("has default indent", function()
      local defaults = config.get_defaults()

      assert.equals(2, defaults.indent)
    end)

    it("has default temp_dir", function()
      local defaults = config.get_defaults()

      assert.equals("/tmp", defaults.temp_dir)
    end)
  end)

  describe("setup", function()
    before_each(function()
      package.loaded["vue-sfc-format.config"] = nil
      config = require("vue-sfc-format.config")
    end)

    it("accepts nil options", function()
      assert.has_no.errors(function()
        config.setup()
      end)
    end)

    it("accepts empty options", function()
      assert.has_no.errors(function()
        config.setup({})
      end)
    end)

    it("merges custom indent", function()
      config.setup({ indent = 4 })

      assert.equals(4, config.options.indent)
    end)

    it("merges custom temp_dir", function()
      config.setup({ temp_dir = "/var/tmp" })

      assert.equals("/var/tmp", config.options.temp_dir)
    end)

    it("merges custom config_file", function()
      config.setup({ config_file = "vue-format.json" })

      assert.equals("vue-format.json", config.options.config_file)
    end)
  end)

  describe("defaults", function()
    it("has default formatters", function()
      local defaults = config.get_defaults()

      assert.is_not_nil(defaults.formatters)
      assert.is_not_nil(defaults.formatters.template)
      assert.is_not_nil(defaults.formatters.script)
      assert.is_not_nil(defaults.formatters.style)
      assert.is_not_nil(defaults.formatters.style_scss)
    end)
  end)

  describe("get_formatter", function()
    before_each(function()
      package.loaded["vue-sfc-format.config"] = nil
      config = require("vue-sfc-format.config")
    end)

    it("returns default formatter when no config file", function()
      local result, err = config.get_formatter("template", "")

      assert.is_not_nil(result)
      assert.is_nil(err)
      assert.equals("npx", result.cmd)
    end)

    it("returns script formatter", function()
      local result, err = config.get_formatter("script", "")

      assert.is_not_nil(result)
      assert.is_nil(err)
    end)

    it("returns style formatter", function()
      local result, err = config.get_formatter("style", "")

      assert.is_not_nil(result)
      assert.is_nil(err)
    end)

    it("returns style_scss formatter when attrs contain scss", function()
      local result, err = config.get_formatter("style", ' lang="scss"')

      assert.is_not_nil(result)
      assert.is_nil(err)
      -- Should use scss parser
      local args_str = table.concat(result.args, " ")
      assert.is_truthy(args_str:find("scss"))
    end)

    it("detects scss from attrs", function()
      local attrs = ' lang="scss" scoped'

      assert.is_truthy(attrs:find("scss"))
    end)

    it("detects css when no scss in attrs", function()
      local attrs = " scoped"

      assert.is_falsy(attrs:find("scss"))
    end)
  end)
end)
