# project-color-nvim

A Neovim plugin that persists your current theme using [nvim-project-config](https://github.com/rektide/project-settings-nvim), allowing you to maintain consistent color schemes across different projects and sessions.

## Features

- Automatically loads theme from project config on startup
- Tracks and persists theme changes using nvim-project-config
- Stores theme in `color-persist` key in project JSON
- Works with any Neovim colorscheme

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  'rektide/project-color',
  dependencies = { 'rektide/project-settings-nvim' },
}
```

Using [packer.nvim](https://github.com/wbthomason/packer.nvim):

```lua
use {
  'rektide/project-color',
  requires = { 'rektide/project-settings-nvim' },
}
```

**Auto-setup:** Plugin automatically runs `setup()` with defaults on startup. If you want to configure options, disable auto-setup first:

```lua
vim.g.project_color_nvim_autosetup = false

require('project-color-nvim').setup({
  enabled = true,
  autoload = true,
  persist = true,
})
```

## Configuration

Plugin automatically runs `setup()` with defaults on startup. To customize options, disable auto-setup first:

```lua
vim.g.project_color_nvim_autosetup = false

require('project-color-nvim').setup({
  enabled = true,
  autoload = true,
  persist = true,
  key = 'color-persist',
})
```

**Options:**

| Option     | Type    | Default            | Description                                                                                                           |
| ---------- | ------- | ------------------ | --------------------------------------------------------------------------------------------------------------------- |
| `enabled`  | boolean | `true`             | Enable/disable plugin. When false, plugin does nothing.                                                               |
| `autoload` | boolean | `true`             | Automatically load theme from project config on startup. When false, plugin watches changes but doesn't load a theme. |
| `persist`  | boolean | `true`             | Persist theme changes to project config. When false, plugin loads theme but doesn't write changes.                    |
| `key`      | string  | `'color-persist'`   | JSON key name to store theme in project config.                                                                       |

## How It Works

### Load Flow

The plugin checks for theme in project config when Neovim starts:

```mermaid
flowchart TD
    NeovimStarts[Neovim Starts] --> LoadProjectConfig[Load project config]
    LoadProjectConfig --> ThemeSet{color-persist key set?}
    ThemeSet -->|Yes| LoadTheme[Load color-persist theme]
    ThemeSet -->|No| UseDefaultTheme[Use default theme]
    LoadTheme --> SetupWatcher[Setup theme change watcher]
    UseDefaultTheme --> SetupWatcher
    SetupWatcher --> Ready[Ready for use]
```

### Theme Change Flow

When you change your theme, the plugin updates the project config:

```mermaid
flowchart TD
    A[Theme Change Detected] --> B[Get current theme name]
    B --> C[Load project config]
    C --> D[Update color-persist key]
    D --> E[Save project config]
    E --> F[Config updated]
```

## Architecture

The plugin uses [nvim-project-config](https://github.com/rektide/project-settings-nvim) for all configuration persistence:

### Module Structure

```
lua/project-color-nvim/
├── init.lua       - Main plugin entry point and orchestration
├── config.lua     - Plugin configuration management
├── theme.lua      - Theme retrieval and colorscheme loading
└── autocmds.lua   - Autocmd setup and event handling
```

### Module Responsibilities

**config.lua**

- Defines default plugin configuration
- Handles `setup(opts)` - merges user options with defaults
- Provides configuration validation

**theme.lua**

- Retrieves current theme name from Neovim
- Loads a specified colorscheme
- Handles theme loading errors gracefully
- Provides wrapper around `vim.g.colors_name` and `vim.cmd.colorscheme`

**autocmds.lua**

- Sets up `ColorScheme` autocmd listener
- Manages plugin lifecycle events
- Coordinates theme persistence on theme changes using nvim-project-config

**init.lua**

- Main entry point for the plugin
- Orchestrates the initialization sequence
- Coordinates loading theme from project config on startup
- Exports public API (`setup()`)
- Connects all modules together

## Usage

1. Ensure you have nvim-project-config installed and configured
2. Start Neovim in your project directory
3. The plugin will automatically load the theme stored in the `color-persist` key of your project config
4. When you change your theme with `:colorscheme <name>`, the plugin updates the `color-persist` key in your project config

For detailed technical specification of how project-color-nvim integrates with nvim-project-config, see [doc/projectconfig.md](doc/projectconfig.md).

## License

MIT
