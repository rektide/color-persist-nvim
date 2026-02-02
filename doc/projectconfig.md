# project-color-nvim Configuration Specification

This document describes how project-color-nvim stores and retrieves per-project color scheme preferences.

## Storage Format

Color preferences are stored in a JSON file managed by [nvim-project-config](https://github.com/rektide/project-settings-nvim).

### Key

| Key | Type | Description |
|-----|------|-------------|
| `color-persist` | string | Name of the colorscheme to use for this project |

The key name is configurable via the `key` option (default: `"color-persist"`).

### Example File

```json
{
  "color-persist": "tokyonight",
  "other-plugin-settings": "..."
}
```

### File Location

Configuration files are stored in `~/.config/nvim/projects/<project-name>.json`.

The project name is derived automatically by nvim-project-config by walking up the directory tree and looking for marker files like `.git`, `package.json`, etc. This provides more reliable project detection than directory name heuristics.

## Behavior

### Loading

On startup (when `autoload = true`):

1. Read the project JSON file
2. If `color-persist` key exists and is non-empty, call `vim.cmd.colorscheme(theme_name)`

On directory change, the same logic runs if `autoload = true`.

### Saving

When `:colorscheme <name>` is called (when `persist = true`):

1. Catch the `ColorScheme` autocommand
2. Set `npc.ctx.json["color-persist"] = vim.g.colors_name`
3. The metatable automatically writes changes to disk

> **Note**: nvim-project-config uses a reactive metatable on `ctx.json` that automatically persists changes to the last matched JSON file. You don't need to explicitly save.

## Configuration Options

```lua
require('project-color-nvim').setup({
  enabled = true,    -- Enable/disable the plugin entirely
  autoload = true,   -- Load saved theme on startup and dir change
  persist = true,    -- Save theme changes to project config
  key = 'color-persist',  -- JSON key name
  notify = true,     -- Show notifications on load/save
})
```

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enabled` | boolean | `true` | Master enable/disable |
| `autoload` | boolean | `true` | Auto-load theme on startup |
| `persist` | boolean | `true` | Auto-save theme on change |
| `key` | string | `"color-persist"` | JSON key for theme name |
| `notify` | boolean | `true` | Show status notifications |

## User Commands

| Command | Description |
|---------|-------------|
| `:ProjectColorLoad` | Manually load theme from project config |
| `:ProjectColorSave` | Manually save current theme to project config |
| `:ProjectColorClear` | Remove theme from project config |

## Integrating with project-color-nvim

To read the persisted theme from another plugin:

```lua
local projectconfig = require('project-color-nvim.projectconfig')
local data, err = projectconfig.read()
if data and data['color-persist'] then
  print('Saved theme: ' .. data['color-persist'])
end
```

To write a theme:

```lua
local projectconfig = require('project-color-nvim.projectconfig')
local data, _ = projectconfig.read()
data = data or {}
data['color-persist'] = 'gruvbox'
projectconfig.write(data)
```

## Troubleshooting

**Theme not loading?**
```lua
:lua print(vim.inspect(require('project-color-nvim.projectconfig').load_json()))
```

**Theme not saving?**
- Check `:checkhealth project-color-nvim`
- Verify `persist = true` in your config
- Ensure nvim-project-config is installed

---

## Appendix: Source References

Implementation details for contributors and curious readers.

### Core Modules

| Module | Purpose |
|--------|---------|
| [lua/project-color-nvim/init.lua](https://github.com/rektide/color-persist-nvim/blob/main/lua/project-color-nvim/init.lua) | Plugin entry point, setup, commands |
| [lua/project-color-nvim/config.lua](https://github.com/rektide/color-persist-nvim/blob/main/lua/project-color-nvim/config.lua) | Configuration management |
| [lua/project-color-nvim/projectconfig.lua](https://github.com/rektide/color-persist-nvim/blob/main/lua/project-color-nvim/projectconfig.lua) | JSON read/write via nvim-project-config |
| [lua/project-color-nvim/theme.lua](https://github.com/rektide/color-persist-nvim/blob/main/lua/project-color-nvim/theme.lua) | Theme loading utilities |
| [lua/project-color-nvim/autocmds.lua](https://github.com/rektide/color-persist-nvim/blob/main/lua/project-color-nvim/autocmds.lua) | ColorScheme and DirChanged handlers |

### Key Functions

**Loading theme from config** — [lua/project-color-nvim/init.lua#L18-L34](https://github.com/rektide/color-persist-nvim/blob/main/lua/project-color-nvim/init.lua#L18-L34)

```lua
local function load_from_project_config()
  local data = projectconfig.load_json()
  -- ...
  local theme_to_load = data[config.get_key()]
  if theme_to_load and theme_to_load ~= '' then
    theme.load(theme_to_load)
  end
end
```

**Saving theme on ColorScheme event** — [lua/project-color-nvim/autocmds.lua#L14-L48](https://github.com/rektide/color-persist-nvim/blob/main/lua/project-color-nvim/autocmds.lua#L14-L48)

```lua
vim.api.nvim_create_autocmd('ColorScheme', {
  group = augroup_name,
  callback = function()
    -- read current data, update key
    ctx.json[key] = current_theme
    -- metatable automatically persists to disk
  end,
})
```

**Reading project JSON** — [lua/project-color-nvim/projectconfig.lua#L27-L30](https://github.com/rektide/color-persist-nvim/blob/main/lua/project-color-nvim/projectconfig.lua#L27-L30)

```lua
function M.load_json()
  local ctx = M.get_ctx()
  if not ctx or not ctx.json then return {} end
  return ctx.json
end
```

**Writing project JSON** — [lua/project-color-nvim/projectconfig.lua#L32-L44](https://github.com/rektide/color-persist-nvim/blob/main/lua/project-color-nvim/projectconfig.lua#L32-L44)

```lua
function M.save_json(data)
  local ctx = M.get_ctx()
  if not ctx then return false, 'no context' end

  if not ctx.json then
    ctx.json = {}
  end

  for k, v in pairs(data) do
    ctx.json[k] = v
  end

  return true
end
```

**Default configuration** — [lua/project-color-nvim/config.lua#L3-L9](https://github.com/rektide/color-persist-nvim/blob/main/lua/project-color-nvim/config.lua#L3-L9)

```lua
local defaults = {
  enabled = true,
  autoload = true,
  persist = true,
  key = 'color-persist',
  notify = true,
}
```
