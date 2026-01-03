# nvim-color-persist

A Neovim plugin that persists your current theme to a `.env.editor` file, allowing you to maintain consistent color schemes across different projects and sessions.

## Features

- Automatically loads theme from `.env.editor` on startup
- Tracks and persists theme changes
- Supports `EDITOR_COLOR` (general theme) and `NVIM_COLOR` (editor-specific override)
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
  enabled = true,
  autoload = true,
  persist = true,
  env_file = '.env.editor',
})
```

**Options:**

- `enabled` (boolean, default: `true`) - Enable/disable the plugin
- `autoload` (boolean, default: `true`) - Automatically load theme on startup
- `persist` (boolean, default: `true`) - Persist theme changes to env file
- `env_file` (string, default: `'.env.editor'`) - Name of env file to use

## How It Works

### Load Flow

The plugin checks for a `.env.editor` file when Neovim starts:

```mermaid
flowchart TD
    NeovimStarts[Neovim Starts] --> LoadEnvFile[Load .env.editor]
    LoadEnvFile --> NVIMColorSet{NVIM_COLOR set?}
    NVIMColorSet -->|Yes| LoadNvimTheme[Load NVIM_COLOR theme]
    NVIMColorSet -->|No| EditorColorSet{EDITOR_COLOR set?}
    EditorColorSet -->|Yes| LoadEditorTheme[Load EDITOR_COLOR theme]
    EditorColorSet -->|No| UseDefaultTheme[Use default theme]
    LoadNvimTheme --> SetupWatcher[Setup theme change watcher]
    LoadEditorTheme --> SetupWatcher
    UseDefaultTheme --> SetupWatcher
    SetupWatcher --> Ready[Ready for use]
```

### Theme Change Flow

When you change your theme, the plugin updates the `.env.editor` file with a single variable:

```mermaid
flowchart TD
    A[Theme Change Detected] --> B[Get current theme name]
    B --> C[Read .env.editor]
    C --> D{NVIM_COLOR in file?}
    D -->|Yes| E[Update NVIM_COLOR = current theme]
    D -->|No| F[Update EDITOR_COLOR = current theme]
    E --> G[Write to .env.editor]
    F --> G
    G --> H[File updated]
```

## Architecture

The plugin is organized into feature-based modules for clear separation of concerns:

### Module Structure

```
lua/nvim-color-persist/
├── init.lua       - Main plugin entry point and orchestration
├── config.lua     - Configuration management and defaults
├── env.lua        - Env file parsing and writing operations
├── theme.lua      - Theme retrieval and colorscheme loading
└── autocmds.lua   - Autocmd setup and event handling
```

### Module Responsibilities

**config.lua**

- Defines default plugin configuration (`env_file`, `augroup`, etc.)
- Handles `setup(opts)` - merges user options with defaults
- Provides configuration validation
- Exports getter functions for config values
- Manages configuration constants

**env.lua**

- Parses dotenv-format files (KEY=value)
- Writes updated variables to env files
- Handles file I/O operations for `.env.editor`
- Manages key constants (`NVIM_COLOR`, `EDITOR_COLOR`)
- Provides pure functions for parsing and impure functions for writing

**theme.lua**

- Retrieves current theme name from Neovim
- Loads a specified colorscheme
- Handles theme loading errors gracefully
- Provides wrapper around `vim.g.colors_name` and `vim.cmd.colorscheme`

**autocmds.lua**

- Sets up the `ColorScheme` autocmd listener
- Creates the plugin's augroup
- Manages plugin lifecycle events
- Coordinates theme persistence on theme changes

**init.lua**

- Main entry point for the plugin
- Orchestrates the initialization sequence
- Coordinates loading theme from env file on startup
- Exports public API (`setup()`)
- Connects all modules together

## Environment Variables

The plugin checks for theme variables in your `.env.editor` file in the following priority order:

- `NVIM_COLOR` - Editor-specific override (checked first)
- `EDITOR_COLOR` - General theme variable (fallback)

**Write Behavior:** When you change your theme, the plugin updates only one variable:

- If `NVIM_COLOR` exists in the file, it updates that variable
- Otherwise, it updates `EDITOR_COLOR`

## Usage

1. Create a `.env.editor` file in your project root
2. Set your preferred theme using `EDITOR_COLOR` (for general use) or `NVIM_COLOR` (for Neovim-specific override)
3. Start Neovim in the project directory
4. The plugin will automatically load the specified theme (prioritizes `NVIM_COLOR` if set)
5. When you change your theme with `:colorscheme <name>`, the plugin updates the appropriate variable in `.env.editor`:
   - Updates `NVIM_COLOR` if it exists in the file
   - Otherwise updates `EDITOR_COLOR`

## License

MIT
