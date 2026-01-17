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
  local data, err = projectconfig.read()
  if err then
    vim.notify(err, vim.log.levels.WARN)
    return
  end

  local theme_to_load = data['color-persist']
  if theme_to_load and theme_to_load ~= '' then
    local ok, load_err = theme.load(theme_to_load)
    if not ok then
      vim.notify('Failed to load theme: ' .. (load_err or 'unknown error'), vim.log.levels.WARN)
    end
  end
end

local function save_current_theme()
  if not config.should_persist() then
    vim.notify('Theme persistence is disabled in config', vim.log.levels.WARN)
    return false
  end

  local current_theme = theme.get_current()
  if current_theme == '' then
    vim.notify('No theme currently loaded', vim.log.levels.WARN)
    return false
  end

  local data, err = projectconfig.read()
  if err then
    vim.notify('Failed to read project config: ' .. err, vim.log.levels.WARN)
    return false
  end

  data['color-persist'] = current_theme

  local save_ok, save_err = projectconfig.write(data)
  if not save_ok then
    vim.notify('Failed to save project config: ' .. (save_err or 'unknown error'), vim.log.levels.WARN)
    return false
  end

  vim.notify('Theme saved to project config: ' .. current_theme, vim.log.levels.INFO)
  return true
end

local function clear_persisted_theme()
  local data, err = projectconfig.read()
  if err then
    vim.notify('Failed to read project config: ' .. err, vim.log.levels.WARN)
    return false
  end

  if not data['color-persist'] then
    vim.notify('No persisted theme found', vim.log.levels.INFO)
    return true
  end

  data['color-persist'] = nil

  local save_ok, save_err = projectconfig.write(data)
  if not save_ok then
    vim.notify('Failed to clear project config: ' .. (save_err or 'unknown error'), vim.log.levels.WARN)
    return false
  end

  vim.notify('Persisted theme cleared', vim.log.levels.INFO)
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
