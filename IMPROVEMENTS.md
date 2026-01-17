# project-color-nvim Improvements

## Problem Areas

### 1. Incorrect `pcall` Result Handling (Bug)

**Location:** [init.lua#L20-L23](file:///home/rektide/src/color-persist/nvim/lua/project-color-nvim/init.lua#L20-L23)

The current pattern is broken:

```lua
local ok, err = pcall(theme.load, theme_to_load)
if not ok then
  vim.notify('Failed to load theme: ' .. err, vim.log.levels.WARN)
end
```

`theme.load()` returns `(false, "error message")` on failure. When wrapped in `pcall`, this becomes `(true, false, "error message")`, so `ok` is `true` and the error is silently ignored.

**Fix:** Since `theme.load()` already handles errors internally with `pcall`, call it directly:

```lua
local ok, err = theme.load(theme_to_load)
if not ok then
  vim.notify('Failed to load theme: ' .. (err or 'unknown error'), vim.log.levels.WARN)
end
```

Same issue exists for `autocmds.setup()` at [init.lua#L42-L45](file:///home/rektide/src/color-persist/nvim/lua/project-color-nvim/init.lua#L42-L45).

### 2. Double Notification on Theme Load Failure

**Location:** [theme.lua#L14](file:///home/rektide/src/color-persist/nvim/lua/project-color-nvim/theme.lua#L14) and [init.lua#L22](file:///home/rektide/src/color-persist/nvim/lua/project-color-nvim/init.lua#L22)

Both `theme.load()` and `load_from_project_config()` call `vim.notify()` on failure. If the pcall bug were fixed, users would see two error messages.

**Fix:** Choose one layer for notifications. Recommended: `theme.load()` returns errors silently; callers decide messaging policy.

### 3. Auto-Setup Breaks Lazy Loading Configuration

**Location:** [plugin/project-color.lua](file:///home/rektide/src/color-persist/nvim/plugin/project-color.lua)

```lua
if vim.fn.has("nvim-0.5") == 1 then
  require("project-color-nvim").setup()
end
```

This runs `setup()` with defaults as soon as the plugin is sourced, before users can pass options. With lazy.nvim and similar managers, this causes:
- User options ignored if setup happens before their config function runs
- Potential double-setup
- Autocmds registered earlier than expected

**Fix:** Delete this file entirely and require users to call `setup()` from their plugin manager config (which is already documented in README). Or add a guard:

```lua
if vim.g.project_color_nvim_autosetup ~= false and vim.g.loaded_project_color_nvim ~= 1 then
  vim.g.loaded_project_color_nvim = 1
  require("project-color-nvim").setup()
end
```

### 4. Unnecessary Writes on ColorScheme Event

**Location:** [autocmds.lua#L31-L41](file:///home/rektide/src/color-persist/nvim/lua/project-color-nvim/autocmds.lua#L31-L41)

When the plugin loads a theme on startup, it triggers `ColorScheme`, which immediately writes the same value back. Every `:colorscheme` command writes, even if the theme hasn't changed.

**Fix:** Check before writing:

```lua
if data['color-persist'] == current_theme then
  return
end
```

### 5. Health Check Inaccuracies

**Location:** [health.lua](file:///home/rektide/src/color-persist/nvim/lua/project-color-nvim/health.lua)

- `config.check_loaded()` is always true if the module file exists—doesn't indicate whether `setup()` ran
- `autocmds.is_registered()` returns true if the API call succeeds, even with zero autocmds registered

**Fix:** 
- Add `M._did_setup = true` flag in `init.lua` after setup completes; check that in health
- Check `#autocmds > 0` rather than just whether the call succeeded

### 6. Documentation Mentions Wrong File

**Location:** [doc/project-color-nvim.txt#L54-L62](file:///home/rektide/src/color-persist/nvim/doc/project-color-nvim.txt#L54-L62)

Documentation references `.env.editor` but the plugin never touches files directly—that's handled by nvim-projectconfig based on its configuration.

**Fix:** Say "uses nvim-projectconfig's configured project JSON file" instead of specific filenames.

---

## Code Clarity Improvements

### 1. Consolidate nvim-projectconfig Access

The pattern `pcall(require, 'nvim-projectconfig')` followed by `load_json`/`save_json` appears in three places. Extract to a helper:

```lua
-- projectconfig.lua
local M = {}

function M.get()
  local ok, pc = pcall(require, 'nvim-projectconfig')
  if not ok then return nil, "nvim-projectconfig not available" end
  return pc
end

function M.read()
  local pc, err = M.get()
  if not pc then return nil, err end
  local ok, data = pcall(pc.load_json)
  if not ok or not data then return {}, nil end
  return data, nil
end

function M.write(data)
  local pc, err = M.get()
  if not pc then return false, err end
  local ok, save_err = pcall(pc.save_json, data)
  return ok, save_err
end

return M
```

### 2. Validate API Exists for Non-Existent Function

**Location:** [autocmds.lua#L71](file:///home/rektide/src/color-persist/nvim/lua/project-color-nvim/autocmds.lua#L71)

`vim.api.nvim_get_augroups_by_name` doesn't exist in Neovim's API. This function will always fail. If you need to check augroup existence, use:

```lua
local ok = pcall(vim.api.nvim_get_autocmds, { group = augroup_name })
```

### 3. Module-Level State Tracking

Add explicit state tracking for debugging and health checks:

```lua
-- init.lua
M._state = {
  setup_called = false,
  setup_succeeded = false,
  theme_loaded = nil,
}
```

---

## Usability Enhancements

### 1. Add User Commands

Provide explicit control for users who want manual operation:

```lua
vim.api.nvim_create_user_command('ProjectColorLoad', function()
  load_from_project_config()
end, { desc = 'Load theme from project config' })

vim.api.nvim_create_user_command('ProjectColorSave', function()
  -- force save current theme
end, { desc = 'Save current theme to project config' })

vim.api.nvim_create_user_command('ProjectColorClear', function()
  -- remove color-persist key from project config
end, { desc = 'Clear persisted theme' })
```

### 2. Directory Change Support

When users change projects within one Neovim instance, the theme should update:

```lua
vim.api.nvim_create_autocmd('DirChanged', {
  group = augroup_name,
  callback = function()
    if config.should_autoload() then
      load_from_project_config()
    end
  end,
})
```

### 3. Configurable JSON Key

Allow users to customize the storage key:

```lua
defaults = {
  enabled = true,
  autoload = true,
  persist = true,
  key = 'color-persist',  -- NEW: customizable key name
}
```

### 4. Notification Verbosity Control

Let users control how noisy the plugin is:

```lua
defaults = {
  -- ...
  notify = true,  -- or log_level = vim.log.levels.WARN
}
```

### 5. Minimum Version Declaration

The plugin file checks for `nvim-0.5` but uses APIs that may require newer versions (health API structure, etc.). Declare and check a realistic minimum:

```lua
if vim.fn.has("nvim-0.8") == 0 then
  vim.notify("project-color-nvim requires Neovim 0.8+", vim.log.levels.ERROR)
  return
end
```

---

## Summary

| Priority | Issue | Effort |
|----------|-------|--------|
| 🔴 High | pcall result handling bug | Small |
| 🔴 High | Auto-setup breaking lazy loading | Small |
| 🟡 Medium | Unnecessary writes on startup | Small |
| 🟡 Medium | Double notifications | Small |
| 🟡 Medium | Health check inaccuracies | Small |
| 🟡 Medium | Doc references wrong filename | Small |
| 🟢 Low | Consolidate projectconfig access | Medium |
| 🟢 Low | Add user commands | Medium |
| 🟢 Low | DirChanged support | Small |
| 🟢 Low | Configurable options (key, notify) | Small |
