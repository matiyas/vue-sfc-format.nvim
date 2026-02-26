package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

describe("parser", function()
  local parser

  setup(function()
    _G.vim = _G.vim or {}
    _G.vim.fn = _G.vim.fn or {}
    _G.vim.api = _G.vim.api or {}
    _G.vim.deepcopy = function(t)
      return t
    end

    parser = require("vue-sfc-format.parser")
  end)

  describe("find_next_open_tag", function()
    it("finds opening tag at start", function()
      local content = "<template><div></div></template>"
      local pos = parser.find_next_open_tag(content, "template", 1)

      assert.equals(1, pos)
    end)

    it("finds opening tag with attributes", function()
      local content = '<template lang="pug"><div></div></template>'
      local pos = parser.find_next_open_tag(content, "template", 1)

      assert.equals(1, pos)
    end)

    it("returns nil when tag not found", function()
      local content = "<script>export default {}</script>"
      local pos = parser.find_next_open_tag(content, "template", 1)

      assert.is_nil(pos)
    end)

    it("finds tag from specified position", function()
      local content = "<div><template v-if></template></div>"
      local pos = parser.find_next_open_tag(content, "template", 6)

      assert.equals(6, pos)
    end)
  end)

  describe("find_next_close_tag", function()
    it("finds closing tag", function()
      local content = "<template><div></div></template>"
      local pos = parser.find_next_close_tag(content, "template", 1)

      assert.equals(22, pos)
    end)

    it("returns nil when closing tag not found", function()
      local content = "<template><div></div>"
      local pos = parser.find_next_close_tag(content, "template", 1)

      assert.is_nil(pos)
    end)
  end)

  describe("find_matching_close_tag", function()
    it("finds closing tag for simple case", function()
      local content = "<template><div></div></template>"
      local pos = parser.find_matching_close_tag(content, "template", 11)

      assert.equals(22, pos)
    end)

    it("handles nested template tags", function()
      local content = "<template><template v-if>nested</template></template>"
      local pos = parser.find_matching_close_tag(content, "template", 11)

      assert.equals(43, pos)
    end)

    it("handles multiple nested template tags", function()
      local content = "<template><template v-if>a</template><template v-else>b</template></template>"
      local pos = parser.find_matching_close_tag(content, "template", 11)

      assert.equals(67, pos)
    end)

    it("returns nil for unclosed tag", function()
      local content = "<template><div></div>"
      local pos = parser.find_matching_close_tag(content, "template", 11)

      assert.is_nil(pos)
    end)
  end)

  describe("extract_section", function()
    it("extracts template section", function()
      local content = "<template><div>Hello</div></template>"
      local section = parser.extract_section(content, "template")

      assert.is_not_nil(section)
      assert.equals("", section.attrs)
      assert.equals("<div>Hello</div>", section.content)
    end)

    it("extracts section with attributes", function()
      local content = '<script setup lang="ts">const x = 1</script>'
      local section = parser.extract_section(content, "script")

      assert.is_not_nil(section)
      assert.equals(' setup lang="ts"', section.attrs)
      assert.equals("const x = 1", section.content)
    end)

    it("extracts style section with lang attribute", function()
      local content = '<style lang="scss" scoped>.foo { color: red; }</style>'
      local section = parser.extract_section(content, "style")

      assert.is_not_nil(section)
      assert.equals(' lang="scss" scoped', section.attrs)
      assert.equals(".foo { color: red; }", section.content)
    end)

    it("returns nil for missing section", function()
      local content = "<template><div></div></template>"
      local section = parser.extract_section(content, "script")

      assert.is_nil(section)
    end)

    it("handles multiline content", function()
      local content = [[<template>
  <div>
    <span>Hello</span>
  </div>
</template>]]
      local section = parser.extract_section(content, "template")

      assert.is_not_nil(section)
      assert.is_truthy(section.content:find("<div>"))
      assert.is_truthy(section.content:find("<span>Hello</span>"))
    end)

    it("handles nested template tags correctly", function()
      local content = [[<template>
  <div>
    <template v-if="show">
      <span>Visible</span>
    </template>
  </div>
</template>]]
      local section = parser.extract_section(content, "template")

      assert.is_not_nil(section)
      assert.is_truthy(section.content:find("<template v%-if", 1, false))
      assert.is_truthy(section.content:find("</template>", 1, true))
      assert.is_truthy(section.content:find("<span>Visible</span>", 1, true))
    end)
  end)

  describe("wrap_section", function()
    it("wraps content with tag", function()
      local result = parser.wrap_section("template", "", "<div>Hello</div>")

      assert.equals("<template>\n<div>Hello</div>\n</template>\n", result)
    end)

    it("includes attributes", function()
      local result = parser.wrap_section("script", ' setup lang="ts"', "const x = 1")

      assert.equals('<script setup lang="ts">\nconst x = 1\n</script>\n', result)
    end)
  end)

  describe("indent", function()
    it("indents single line", function()
      local result = parser.indent("hello", 2)

      assert.equals("  hello", result)
    end)

    it("indents multiple lines", function()
      local result = parser.indent("line1\nline2", 2)

      assert.equals("  line1\n  line2", result)
    end)

    it("preserves empty lines", function()
      local result = parser.indent("line1\n\nline2", 2)

      assert.equals("  line1\n\n  line2", result)
    end)

    it("uses custom indent size", function()
      local result = parser.indent("hello", 4)

      assert.equals("    hello", result)
    end)

    it("defaults to 2 spaces", function()
      local result = parser.indent("hello")

      assert.equals("  hello", result)
    end)
  end)
end)
