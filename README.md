# vue-sfc-format.nvim

A Neovim plugin that formats Vue Single File Components (SFC) by applying configurable formatters to each section separately.

## Core Purpose

When working with Vue SFC files, you often want different formatting for different sections:
- **Template**: HTML formatting with specific indentation rules
- **Script**: JavaScript/TypeScript formatting with your preferred style
- **Style**: CSS/SCSS formatting

This plugin extracts each section, formats it with the appropriate tool, and reassembles the file. It correctly handles nested template tags (e.g., `<template v-if>`, `<template v-else>`) using depth-balanced tag matching.

## Key Features

- Configurable formatters for each section via JSON config
- Automatic SCSS detection from `lang="scss"` attribute
- Handles nested template tags correctly
- Provides `:VueSfcFormat` command
- Integrates with formatter.nvim

## Requirements

- Neovim >= 0.9.0
- Node.js with npx
- js-beautify (`npm install -g js-beautify`)
- prettier (`npm install -g prettier`)

## Installation

### lazy.nvim

```lua
{
  "matiyas/vue-sfc-format.nvim",
  ft = { "vue" },
  opts = {},
  keys = {
    {
      "<leader>fv",
      function()
        require("vue-sfc-format").format()
      end,
      desc = "Format Vue SFC",
      ft = "vue",
    },
  },
}
```

### packer.nvim

```lua
use({
  "matiyas/vue-sfc-format.nvim",
  ft = { "vue" },
  config = function()
    require("vue-sfc-format").setup()
  end,
})
```

## Configuration

### Plugin Options

```lua
require("vue-sfc-format").setup({
  config_file = ".vue-sfc-format.json",  -- JSON config file name
  indent = 2,                             -- Indentation for template content
  temp_dir = "/tmp",                      -- Temp file directory
})
```

### JSON Configuration File

Create a `.vue-sfc-format.json` file in your project root:

```json
{
  "formatters": {
    "template": {
      "cmd": "npx",
      "args": [
        "js-beautify",
        "--type", "html",
        "--indent-size", "2",
        "--wrap-attributes", "force-aligned",
        "--wrap-line-length", "120",
        "--indent-inner-html",
        "--preserve-newlines",
        "--max-preserve-newlines", "2"
      ]
    },
    "script": {
      "cmd": "npx",
      "args": [
        "prettier",
        "--parser", "babel",
        "--semi", "false",
        "--single-quote",
        "--trailing-comma", "none",
        "--tab-width", "2",
        "--print-width", "120"
      ]
    },
    "style": {
      "cmd": "npx",
      "args": [
        "prettier",
        "--parser", "css",
        "--tab-width", "2",
        "--print-width", "120"
      ]
    },
    "style_scss": {
      "cmd": "npx",
      "args": [
        "prettier",
        "--parser", "scss",
        "--tab-width", "2",
        "--print-width", "120"
      ]
    }
  }
}
```

The plugin automatically uses `style_scss` when `<style lang="scss">` is detected.

## Usage

### Command

```vim
:VueSfcFormat
```

### Lua API

```lua
-- Format current buffer
require("vue-sfc-format").format()

-- Format specific buffer
require("vue-sfc-format").format(bufnr)
```

### formatter.nvim Integration

```lua
require("formatter").setup({
  filetype = {
    vue = {
      function()
        return require("vue-sfc-format").formatter_nvim_config()
      end,
    },
  },
})
```

## Example

Given this Vue file:

```vue
<template>
<div class="container"><span>Hello</span></div>
</template>

<script>
export default {name: 'MyComponent',data() {return {message: 'Hello'}}}
</script>

<style lang="scss" scoped>
.container {color: red;span {font-weight: bold;}}
</style>
```

After formatting:

```vue
<template>
  <div class="container">
    <span>Hello</span>
  </div>
</template>

<script>
export default {
  name: 'MyComponent',
  data() {
    return { message: 'Hello' }
  }
}
</script>

<style lang="scss" scoped>
.container {
  color: red;
  span {
    font-weight: bold;
  }
}
</style>
```

## License

MIT
