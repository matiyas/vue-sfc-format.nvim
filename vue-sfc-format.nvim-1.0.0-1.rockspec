rockspec_format = "3.0"
package = "vue-sfc-format.nvim"
version = "1.0.0-1"

description = {
  summary = "Format Vue SFC files with configurable formatters for each section",
  detailed = [[
    A Neovim plugin that formats Vue Single File Components by applying
    different formatters to each section (template, script, style).
    Supports Prettier, js-beautify, and custom formatters via JSON config.
    Features automatic SCSS detection, per-section indentation, and CLI tool.
  ]],
  license = "MIT",
  homepage = "https://github.com/matiyas/vue-sfc-format.nvim",
  issues_url = "https://github.com/matiyas/vue-sfc-format.nvim/issues",
  maintainer = "matiyas",
  labels = {
    "neovim",
    "neovim-plugin",
    "vue",
    "vue-sfc",
    "formatter",
    "code-formatting",
    "prettier",
    "javascript",
    "scss",
    "lua",
  },
}

dependencies = {
  "lua >= 5.1",
}

source = {
  url = "git://github.com/matiyas/vue-sfc-format.nvim.git",
  tag = "v1.0.0",
}

build = {
  type = "builtin",
  copy_directories = { "lua", "plugin", "doc" },
}
