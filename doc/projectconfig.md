# project-color Configuration Specification

This document describes how project-color-nvim stores and retrieves color scheme configuration using nvim-projectconfig.

## Overview

project-color-nvim uses nvim-projectconfig to persist color scheme preferences per project. The theme name is stored in the `color-persist` key of the project's JSON configuration file.

## Storage Format

The color theme is stored as a string value in the project JSON file:

```json
{
  "color-persist": "tokyonight"
}
```

### Key

| Key | Type | Description |
|-----|------|-------------|
| `color-persist` | string | The name of the Neovim colorscheme to use for this project |

### File Path Calculation

The config file path is calculated by `nvim-projectconfig.get_config_by_ext("json")`:

```lua
local project_dir = vim.fn.stdpath("config") .. "/projects/"  -- Default: ~/.config/nvim/projects/
local project_name = vim.fn.fnamemodify(vim.loop.cwd(), ":p:h:t")
local file_path = project_dir .. project_name .. ".json"
```

**Important**: `project_name` uses modifiers `:p:h:t`:
- `:p` - Expand to full path
- `:h` - Get parent directory  
- `:t` - Get last component (directory name)

This extracts the **immediate parent directory name** of current working directory.

**Examples**:

| CWD | Project Name (`:p:h:t`) | Config File |
|-----|---------------------------|-------------|
| `/home/user/projects/myapp` | `projects` | `~/.config/nvim/projects/projects.json` |
| `/home/user/projects/myapp/src` | `myapp` | `~/.config/nvim/projects/myapp.json` |
| `/home/user/projects/myapp/src/lib` | `src` | `~/.config/nvim/projects/src.json` |
| `/home/user/work/project-name` | `work` | `~/.config/nvim/projects/work.json` |

**Note**: Working from project root (not subdirectories) gives the expected project name. Working from subdirectories uses the parent directory name.

### Example Configuration Files

A project configuration file with color-persist setting:

```json
{
  "color-persist": "dracula",
  "lsp": {
    "enabled": true
  },
  "tabs": {
    "size": 2
  }
}
```

Minimal example with only color-persist:

```json
{
  "color-persist": "gruvbox"
}
```

## Loading Flow

When Neovim starts in a project directory:

1. Plugin calls `nvim-projectconfig.load_json()`
2. Checks if `color-persist` key exists in returned data
3. If key exists and is a non-empty string:
   - Loads the colorscheme using `vim.cmd.colorscheme(theme_name)`
4. If key does not exist or is empty:
   - No action taken, uses default theme

### Pseudocode

```lua
local projectconfig = require('nvim-projectconfig')
local data = projectconfig.load_json()

if data and data['color-persist'] and data['color-persist'] ~= '' then
  vim.cmd.colorscheme(data['color-persist'])
end
```

### Implementation Details

1. **Get current working directory**:
   ```lua
   local cwd = vim.loop.cwd()
   ```

2. **Calculate project name**:
   ```lua
   local project_name = vim.fn.fnamemodify(cwd, ":p:h:t")
   ```

3. **Construct file path**:
   ```lua
   local project_dir = vim.fn.stdpath("config") .. "/projects/"
   local jsonfile = project_dir .. project_name .. ".json"
   ```

4. **Check file readability**:
   ```lua
   if vim.fn.filereadable(jsonfile) == 1 then
   ```

5. **Read entire file**:
   ```lua
   local f = io.open(jsonfile, "r")
   local data = f:read("*a")  -- Read entire file
   f:close()
   ```

6. **Parse JSON**:
   ```lua
   local json_decode = vim.json and vim.json.decode or vim.fn.json_decode
   local jdata = json_decode(data)
   ```

7. **Return parsed table or nil** on any error

## Saving Flow

When the user changes their colorscheme via `:colorscheme <name>`:

1. Plugin catches the `ColorScheme` autocommand event
2. Retrieves current theme name via `vim.g.colors_name`
3. Calls `nvim-projectconfig.load_json()` to get existing project data
4. Updates the `color-persist` key with the current theme name
5. Calls `nvim-projectconfig.save_json(data)` to persist changes

### Pseudocode

```lua
local projectconfig = require('nvim-projectconfig')
local data = projectconfig.load_json() or {}
local current_theme = vim.g.colors_name

data['color-persist'] = current_theme
projectconfig.save_json(data)
```

### Implementation Details

1. **Get current working directory**:
   ```lua
   local cwd = vim.loop.cwd()
   ```

2. **Calculate project name**:
   ```lua
   local project_name = vim.fn.fnamemodify(cwd, ":p:h:t")
   ```

3. **Construct file path**:
   ```lua
   local project_dir = vim.fn.stdpath("config") .. "/projects/"
   local jsonfile = project_dir .. project_name .. ".json"
   ```

4. **Create parent directories** if needed:
   ```lua
   if vim.fn.isdirectory(project_dir) == 0 then
     vim.fn.mkdir(project_dir, "p")  -- Create with parents
   end
   ```

5. **Open file for writing**:
   ```lua
   local fp = assert(io.open(jsonfile, "w"))
   ```

6. **Encode to JSON**:
   ```lua
   local json_encode = vim.json and vim.json.encode or vim.fn.json_encode
   local json_string = json_encode(json_table)
   ```

7. **Write and close**:
   ```lua
   fp:write(json_string)
   fp:close()
   ```

**Important**: `save_json()` **overwrites entire JSON file**, not doing a merge or partial update. Existing data must be loaded first if you want to preserve other keys.

## Behavior Details

### Autoload Behavior

- Controlled by the `autoload` configuration option (default: `true`)
- When `false`: Plugin watches for changes but does not load a theme on startup
- When `true`: Automatically loads the saved theme on startup

### Persist Behavior

- Controlled by the `persist` configuration option (default: `true`)
- When `false`: Plugin loads theme but does not write changes to project config
- When `true`: Saves theme changes to project config

### Enabled Behavior

- Controlled by the `enabled` configuration option (default: `true`)
- When `false`: Plugin does nothing (no loading or saving)

## Integration with nvim-projectconfig

project-color-nvim depends on nvim-projectconfig for:

### 1. File Location Management

nvim-projectconfig determines where project config files are stored using `vim.fn.stdpath("config")`.

**Default location**: `~/.config/nvim/projects/`

Configuration file path is constructed as:
```lua
project_dir .. project_name .. "." .. ext
```

Where:
- `project_dir` - Default: `vim.fn.stdpath("config") .. "/projects/"` → `~/.config/nvim/projects/`
- `project_name` - Calculated from current working directory
- `ext` - File extension (e.g., `"json"`, `"lua"`, `"vim"`)

This can be customized via nvim-projectconfig's `project_dir` option:
```lua
require('nvim-projectconfig').setup({
  project_dir = "~/.config/my-projects/"
})
```

### 2. Project Name Calculation

The project name is calculated using vim's `fnamemodify()` with modifiers `:p:h:t`:

```lua
vim.fn.fnamemodify(vim.loop.cwd(), ":p:h:t")
```

**Modifier breakdown**:
- `:p` - Expand to full path
- `:h` - Get head (parent directory)
- `:t` - Get tail (last component)

**Important**: This extracts the **immediate parent directory name** of the current working directory, not the deepest directory name.

**Examples**:

| Current Directory | `:p:h:t` Result | Config File Path |
|-----------------|---------------------|------------------|
| `/home/user/projects/myapp` | `projects` | `~/.config/nvim/projects/projects.json` |
| `/home/user/projects/myapp/src` | `myapp` | `~/.config/nvim/projects/myapp.json` |
| `/home/user/projects/myapp/src/lib` | `src` | `~/.config/nvim/projects/src.json` |
| `/home/user/work/frontend-app` | `work` | `~/.config/nvim/projects/work.json` |

**Best practice**: Work in your project root (not subdirectories) to get project name as expected.

### 3. JSON Serialization

nvim-projectconfig handles reading/writing JSON files:

**load_json()**:
```lua
function M.load_json()
  local jsonfile = M.get_config_by_ext("json")
  if vim.fn.filereadable(jsonfile) == 1 then
    local f = io.open(jsonfile, "r")
    local data = f:read("*a")
    f:close()
    if data then
      local check, jdata = pcall(vim.json.decode, data)
      if check then
        return jdata
      end
    end
  end
  return nil
end
```

**save_json()**:
```lua
function M.save_json(json_table)
  local jsonfile = M.get_config_by_ext("json")
  local json_encode = vim.json and vim.json.encode or vim.fn.json_encode
  local fp = assert(io.open(jsonfile, "w"))
  fp:write(json_encode(json_table))
  fp:close()
end
```

**Implementation notes**:
- Uses `vim.json.encode/decode` when available, falls back to `vim.fn.json_encode/decode`
- Overwrites entire JSON file (not merge/partial update)
- Creates directories if they don't exist

### 4. File Search Order

When `load_project_config()` is called, it tries sources in this order:

1. **Lua config**: Check for `.lua` file extension
   ```lua
   if execute(M.get_config_by_ext("lua")) then
     return true
   end
   ```

2. **Vim config**: Check for `.vim` file extension
   ```lua
   if execute(M.get_config_by_ext("vim")) then
     return true
   end
   ```

3. **Custom project_config**: Check `project_config` table for matches
   ```lua
   for _, item in pairs(config.project_config) do
     local match = string.match(cwd, item.path)
     if cwd == item.path or match ~= nil and #match > 1 then
       -- Load custom config
       return true
     end
   end
   ```

### 5. Custom Project Configuration

nvim-projectconfig supports custom project configurations via `project_config` option:

```lua
require('nvim-projectconfig').setup({
  project_config = {
    {
      -- Match by exact path
      path = "/home/user/work/project",
      config = function()
        vim.opt.tabstop = 4
        vim.g.my_project_var = "custom"
      end
    },
    {
      -- Match by Lua regex pattern
      path = "frontend%-app",
      -- Config can be file path
      config = "~/.config/nvim/projects/frontend.lua"
    },
  },
})
```

This allows:
- Custom configuration functions per project
- Custom config file locations
- Lua regex pattern matching for monorepo scenarios

### 6. Directory Change Detection

When `autocmd = true` (default), nvim-projectconfig sets up a `DirChanged` autocmd:

```lua
vim.api.nvim_create_autocmd("DirChanged", {
  group = vim.api.nvim_create_augroup("NvimProjectConfig", { clear = true }),
  pattern = "*",
  callback = function()
    M.load_project_config()
  end,
})
```

This automatically reloads project config when you change directories within Neovim.

## Example Usage

### Setting Up Project Color

1. Open Neovim in your project directory
2. Run `:colorscheme mytheme`
3. The plugin automatically saves `mytheme` to the project config
4. Future sessions in this directory will load `mytheme` automatically

### Manual Configuration

You can also manually edit the project JSON file:

```bash
nvim ~/.config/nvim/projects/myproject.json
```

Edit to include:

```json
{
  "color-persist": "nord"
}
```

## Troubleshooting

### Theme Not Loading

Check that the project JSON file exists and contains the `color-persist` key:

```lua
:lua print(vim.inspect(require('nvim-projectconfig').load_json()))
```

### Theme Not Saving

1. Verify nvim-projectconfig is installed: `:checkhealth nvim-projectconfig`
2. Verify project-color-nvim is enabled: `:checkhealth project-color-nvim`
3. Check that the `persist` option is `true`
4. Verify you're in a project directory that nvim-projectconfig recognizes

## Future Extensions

The `color-persist` key structure is simple (string) but can be extended in the future:

```json
{
  "color-persist": {
    "name": "tokyonight",
    "variant": "night",
    "background": "dark"
  }
}
```

Current implementation stores only the theme name for simplicity and compatibility with all colorschemes.
