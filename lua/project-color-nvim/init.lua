if vim.fn.has("nvim-0.8") == 0 then
  vim.notify("project-color-nvim requires Neovim 0.8+", vim.log.levels.ERROR)
  return {}
end

local M = {}
local config = require('project-color-nvim.config')
local theme = require('project-color-nvim.theme')
local autocmds = require('project-color-nvim.autocmds')
local projectconfig = require('project-color-nvim.projectconfig')

M._state = {
  setup_called = false,
  setup_succeeded = false,
  theme_loaded = nil,
}

local function load_from_project_config()
  local pc = projectconfig.get()
  if not pc then return end

  local data = pc.load_json()
  if not data then
    return
  end

  local theme_to_load = data[config.get_key()]
  if theme_to_load and theme_to_load ~= '' then
    local ok, load_err = theme.load(theme_to_load)
    if not ok and config.should_notify() then
      vim.notify('Failed to load theme: ' .. (load_err or 'unknown error'), vim.log.levels.WARN)
    end
  end
end

local function save_current_theme()
  if not config.should_persist() then
    if config.should_notify() then
      vim.notify('Theme persistence is disabled in config', vim.log.levels.WARN)
    end
    return false
  end

  local current_theme = theme.get_current()
  if current_theme == '' then
    if config.should_notify() then
      vim.notify('No theme currently loaded', vim.log.levels.WARN)
    end
    return false
  end

  local pc = projectconfig.get()
  if not pc then
    if config.should_notify() then
      vim.notify('nvim-project-config not available', vim.log.levels.WARN)
    end
    return false
  end

  local data = pc.load_json() or {}

  data[config.get_key()] = current_theme

  local save_ok, save_err = pcall(pc.save_json, data)
  if not save_ok then
    if config.should_notify() then
      vim.notify('Failed to save project config: ' .. (save_err or 'unknown error'), vim.log.levels.WARN)
    end
    return false
  end

  if config.should_notify() then
    vim.notify('Theme saved to project config: ' .. current_theme, vim.log.levels.INFO)
  end
  return true
end

local function clear_persisted_theme()
  local pc = projectconfig.get()
  if not pc then
    if config.should_notify() then
      vim.notify('nvim-project-config not available', vim.log.levels.WARN)
    end
    return false
  end

  local data = pc.load_json() or {}
  if not data[config.get_key()] then
    if config.should_notify() then
      vim.notify('No persisted theme found', vim.log.levels.INFO)
    end
    return true
  end

  data[config.get_key()] = nil

  local save_ok, save_err = pcall(pc.save_json, data)
  if not save_ok then
    if config.should_notify() then
      vim.notify('Failed to clear project config: ' .. (save_err or 'unknown error'), vim.log.levels.WARN)
    end
    return false
  end

  if config.should_notify() then
    vim.notify('Persisted theme cleared', vim.log.levels.INFO)
  end
  return true
end

function M.setup(opts)
  M._state.setup_called = true

  local ok, err = pcall(config.setup, opts)
  if not ok then
    vim.notify('project-color-nvim configuration error: ' .. err, vim.log.levels.ERROR)
    M._state.setup_succeeded = false
    return false
  end

  if not config.is_enabled() then
    M._state.setup_succeeded = true
    return true
  end

  if config.should_autoload() then
    load_from_project_config()
  end

  local setup_ok, setup_err = autocmds.setup()
  if not setup_ok then
    vim.notify('project-color-nvim autocmd setup failed: ' .. (setup_err or 'unknown error'), vim.log.levels.ERROR)
    M._state.setup_succeeded = false
    return false
  end

  autocmds.setup_dirchanged_autocmd(load_from_project_config)

  vim.api.nvim_create_user_command('ProjectColorLoad', function()
    load_from_project_config()
  end, { desc = 'Load theme from project config' })

  vim.api.nvim_create_user_command('ProjectColorSave', function()
    save_current_theme()
  end, { desc = 'Save current theme to project config' })

  vim.api.nvim_create_user_command('ProjectColorClear', function()
    clear_persisted_theme()
  end, { desc = 'Clear persisted theme from project config' })

  M._state.setup_succeeded = true
  return true
end

return M
