# Contributing to vue-sfc-format.nvim

First off, thank you for considering contributing to vue-sfc-format.nvim! It's people like you who make the Neovim ecosystem better.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please search the [issue tracker](https://github.com/matiyas/vue-sfc-format.nvim/issues) to see if the problem has already been reported.

If you find a bug, please include:
- Your Neovim version
- Your configuration (the relevant part of your `init.lua` or `init.vim`)
- Your `.vue-sfc-format.json`
- A minimal reproducible example (a `.vue` file that fails to format correctly)
- Expected vs. actual behavior

### Suggesting Enhancements

Feature requests are welcome! Please open an issue and describe:
- The problem this feature would solve
- How you imagine the feature working
- Any alternatives you've considered

### Pull Requests

1. Fork the repository
2. Create a new branch (`git checkout -b feature/my-new-feature`)
3. Make your changes
4. Ensure tests pass and code style is maintained
5. Update documentation (`doc/vue-sfc-format.txt`) if you've added or changed features
6. Commit your changes (`git commit -am 'Add some feature'`)
7. Push to the branch (`git push origin feature/my-new-feature`)
8. Create a new Pull Request

## Development Setup

### Testing

This project uses [vusted](https://github.com/notomo/vusted) for testing.

To run tests locally:
1. Install `vusted`
2. Run `vusted tests/`

### Code Style

We use [Stylua](https://github.com/JohnnyMorganz/StyLua) for Lua code formatting. Please ensure your code follows the project's style by running:
```bash
stylua .
```

We also use [luacheck](https://github.com/mpeterv/luacheck) for linting.
```bash
luacheck .
```

## Community

Please note that this project is released with a [Contributor Code of Conduct](CODE_OF_CONDUCT.md). By participating in this project you agree to abide by its terms.
