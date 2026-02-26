rockspec_format = "3.0"
package = "vue-sfc-format.nvim"
version = "1.0.0-1"

description = {
  summary = "Format Vue SFC files with configurable formatters for each section",
  detailed = [[
    A Neovim plugin that formats Vue Single File Components by applying
    different formatters to each section (template, script, style).
    Supports configurable formatters via JSON config file and correctly
    handles nested template tags.
  ]],
  license = "MIT",
  homepage = "https://github.com/matiyas/vue-sfc-format.nvim",
  labels = { "neovim", "vue", "formatter", "sfc" },
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
