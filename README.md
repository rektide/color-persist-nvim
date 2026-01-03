# nvim-color-persist

A Neovim plugin that persists your current theme to a `.env.editor` file, allowing you to maintain consistent color schemes across different projects and sessions.

## Features

- Automatically loads theme from `.env.editor` on startup
- Tracks and persists theme changes
- Supports both `NVIM_COLOR` (primary) and `EDITOR_COLOR` (fallback) variables
- Works with any Neovim colorscheme

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  'rektide/nvim-color-persist',
  config = function()
    require('nvim-color-persist').setup()
  end
}
```

Using [packer.nvim](https://github.com/wbthomason/packer.nvim):

```lua
use {
  'rektide/nvim-color-persist',
  config = function()
    require('nvim-color-persist').setup()
  end
}
```

## Configuration

```lua
require('nvim-color-persist').setup({
  env_file = '.env.editor',
})
```

## How It Works

### Load Flow

The plugin checks for a `.env.editor` file when Neovim starts:

```mermaid
flowchart TD
    A[Neovim Starts] --> B[Load .env.editor]
    B --> C{NVIM_COLOR set?}
    C -->|Yes| D[Load NVIM_COLOR theme]
    C -->|No| E{EDITOR_COLOR set?}
    E -->|Yes| F[Load EDITOR_COLOR theme]
    E -->|No| G[Use default theme]
    D --> H[Setup theme change watcher]
    F --> H
    G --> H
    H --> I[Ready for use]
```

### Theme Change Flow

When you change your theme, the plugin updates the `.env.editor` file:

```mermaid
flowchart TD
    A[Theme Change Detected] --> B[Get current theme name]
    B --> C[Read .env.editor]
    C --> D[Set NVIM_COLOR = current theme]
    D --> E{EDITOR_COLOR set?}
    E -->|No| F[Set EDITOR_COLOR = current theme]
    E -->|Yes| G{EDITOR_COLOR == NVIM_COLOR?}
    G -->|Yes| F
    G -->|No| H[Keep EDITOR_COLOR unchanged]
    F --> I[Write updated variables to .env.editor]
    H --> I
    I --> J[File updated]
```

## Environment Variables

The plugin looks for these variables in your `.env.editor` file:

- `NVIM_COLOR` - Primary theme variable (takes precedence)
- `EDITOR_COLOR` - Fallback theme variable

Example `.env.editor` file:

```env
NVIM_COLOR=tokyonight
EDITOR_COLOR=tokyonight
```

## Usage

1. Create a `.env.editor` file in your project root
2. Set your preferred theme using either `NVIM_COLOR` or `EDITOR_COLOR`
3. Start Neovim in the project directory
4. The plugin will automatically load the specified theme
5. When you change your theme with `:colorscheme <name>`, the plugin updates the `.env.editor` file

## License

MIT
