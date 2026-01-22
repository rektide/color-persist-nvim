# project-color-nvim Configuration Specification

This document describes how project-color-nvim stores and retrieves per-project color scheme preferences.

## Storage Format

Color preferences are stored in a JSON file managed by [nvim-projectconfig](https://github.com/windwp/nvim-projectconfig).

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

The project name is derived from the **parent directory** of the current working directory using `vim.fn.fnamemodify(cwd, ":p:h:t")`.

| Working Directory | Project Name | Config File |
|-------------------|--------------|-------------|
| `/home/user/code/myapp` | `code` | `~/.config/nvim/projects/code.json` |
| `/home/user/code/myapp/src` | `myapp` | `~/.config/nvim/projects/myapp.json` |

> **Tip**: Work from your project root (not subdirectories) for predictable project names.

## Behavior

### Loading

On startup (when `autoload = true`):

1. Read the project JSON file
2. If `color-persist` key exists and is non-empty, call `vim.cmd.colorscheme(theme_name)`

On directory change, the same logic runs if `autoload = true`.

### Saving

When `:colorscheme <name>` is called (when `persist = true`):

1. Catch the `ColorScheme` autocommand
2. Read current project JSON (or start with empty table)
3. Set `data["color-persist"] = vim.g.colors_name`
4. Write the entire JSON file back

> **Note**: The save overwrites the entire JSON file. Existing keys are preserved by reading first.

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
:lua print(vim.inspect(require('project-color-nvim.projectconfig').read()))
```

**Theme not saving?**
- Check `:checkhealth project-color-nvim`
- Verify `persist = true` in your config
- Ensure nvim-projectconfig is installed

---

## Appendix: Source References

Implementation details for contributors and curious readers.

### Core Modules

| Module | Purpose |
|--------|---------|
| [lua/project-color-nvim/init.lua](https://github.com/rektide/color-persist-nvim/blob/main/lua/project-color-nvim/init.lua) | Plugin entry point, setup, commands |
| [lua/project-color-nvim/config.lua](https://github.com/rektide/color-persist-nvim/blob/main/lua/project-color-nvim/config.lua) | Configuration management |
| [lua/project-color-nvim/projectconfig.lua](https://github.com/rektide/color-persist-nvim/blob/main/lua/project-color-nvim/projectconfig.lua) | JSON read/write via nvim-projectconfig |
| [lua/project-color-nvim/theme.lua](https://github.com/rektide/color-persist-nvim/blob/main/lua/project-color-nvim/theme.lua) | Theme loading utilities |
| [lua/project-color-nvim/autocmds.lua](https://github.com/rektide/color-persist-nvim/blob/main/lua/project-color-nvim/autocmds.lua) | ColorScheme and DirChanged handlers |

### Key Functions

**Loading theme from config** — [lua/project-color-nvim/init.lua#L18-L34](https://github.com/rektide/color-persist-nvim/blob/main/lua/project-color-nvim/init.lua#L18-L34)

```lua
local function load_from_project_config()
  local data, err = projectconfig.read()
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
    -- read current data, update key, write back
    data[key] = current_theme
    projectconfig.write(data)
  end,
})
```

**Reading project JSON** — [lua/project-color-nvim/projectconfig.lua#L9-L15](https://github.com/rektide/color-persist-nvim/blob/main/lua/project-color-nvim/projectconfig.lua#L9-L15)

```lua
function M.read()
  local pc, err = M.get()
  if not pc then return {}, err end
  local ok, data = pcall(pc.load_json)
  if not ok or not data then return {}, nil end
  return data, nil
end
```

**Writing project JSON** — [lua/project-color-nvim/projectconfig.lua#L17-L22](https://github.com/rektide/color-persist-nvim/blob/main/lua/project-color-nvim/projectconfig.lua#L17-L22)

```lua
function M.write(data)
  local pc, err = M.get()
  if not pc then return false, err end
  local ok, save_err = pcall(pc.save_json, data)
  return ok, save_err
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
