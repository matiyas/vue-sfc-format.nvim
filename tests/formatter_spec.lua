package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

describe("formatter", function()
  local formatter
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
            result[k] = v
          end
        end
      end
      return result
    end
    _G.vim.json = _G.vim.json or {}
    _G.vim.json.decode = function(str)
      -- Simple JSON parser for tests
      local json = require("tests.json_helper")
      return json.decode(str)
    end

    config = require("vue-sfc-format.config")
    formatter = require("vue-sfc-format.formatter")
  end)

  describe("format_with_temp_file", function()
    it("creates temp file and executes command", function()
      local test_formatter = {
        cmd = "cat",
        args = {},
      }
      local result = formatter.format_with_temp_file("hello world", test_formatter, "test")

      assert.equals("hello world", result)
    end)

    it("passes arguments to command", function()
      local result = formatter.format_with_temp_file("content", { cmd = "cat", args = {} }, "test")

      assert.equals("content", result)
    end)

    it("works with any custom formatter", function()
      -- Using sed as a custom "formatter" to prove any command works
      local custom_formatter = {
        cmd = "sed",
        args = { "s/foo/bar/g" },
      }
      local result = formatter.format_with_temp_file("foo baz foo", custom_formatter, "custom")

      assert.equals("bar baz bar", result)
    end)

    it("works with formatter that has multiple args", function()
      local custom_formatter = {
        cmd = "tr",
        args = { "a-z", "A-Z", "<" },
      }
      local result = formatter.format_with_temp_file("hello", custom_formatter, "tr-test")

      assert.equals("HELLO", result)
    end)

    it("cleans up temp file after execution", function()
      local test_formatter = {
        cmd = "cat",
        args = {},
      }
      formatter.format_with_temp_file("test", test_formatter, "cleanup-test")

      -- Check that no temp file exists (it's cleaned up)
      local tmp_pattern = config.options.temp_dir .. "/vue-sfc-format-*-cleanup-test"
      local handle = io.popen("ls " .. tmp_pattern .. " 2>/dev/null | wc -l")
      local count = handle:read("*a"):match("%d+")
      handle:close()

      assert.equals("0", count)
    end)
  end)
end)
