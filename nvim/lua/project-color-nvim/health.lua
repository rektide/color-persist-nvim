local M = {}
local config = require('project-color-nvim.config')
local theme = require('project-color-nvim.theme')
local autocmds = require('project-color-nvim.autocmds')

local function check_plugin_loaded()
  local plugin = require('project-color-nvim')
  if plugin._state.setup_succeeded then
    vim.health.ok('project-color-nvim plugin loaded and setup complete')
  elseif plugin._state.setup_called then
    vim.health.error('project-color-nvim setup was called but failed')
  else
    vim.health.warn('project-color-nvim plugin loaded but setup() not called')
  end
end

local function check_config()
  local results = config.validate()

  if not results.valid then
    vim.health.error('Configuration validation failed')
    for _, err in ipairs(results.errors) do
      vim.health.error('  - ' .. err)
    end
  else
    vim.health.ok('Configuration valid')
    vim.health.info('  enabled: ' .. tostring(config.get().enabled))
    vim.health.info('  autoload: ' .. tostring(config.get().autoload))
    vim.health.info('  persist: ' .. tostring(config.get().persist))
  end
end

local function check_theme()
  local status = theme.check_status()

  if status.loaded then
    vim.health.ok('Current theme: ' .. status.theme_name)
  else
    vim.health.warn('No theme loaded')
  end
end

local function check_projectconfig()
  local ok, projectconfig = pcall(require, 'nvim-projectconfig')
  if ok and projectconfig then
    vim.health.ok('nvim-projectconfig plugin available')
  else
    vim.health.error('nvim-projectconfig plugin not available (required dependency)')
  end
end

local function check_project_config()
  local ok, projectconfig = pcall(require, 'nvim-projectconfig')
  if not ok or not projectconfig then
    return
  end

  local config_ok, data = pcall(projectconfig.load_json)
  if not config_ok or not data then
    vim.health.info('No project config found for current project')
    return
  end

  vim.health.ok('Project config loaded')

  if data['color-persist'] then
    vim.health.ok('color-persist key set to: ' .. data['color-persist'])
  else
    vim.health.info('color-persist key not set in project config')
  end
end

local function check_autocmds()
  local status = autocmds.get_status()

  if status.registered and status.count > 0 then
    vim.health.ok('ColorScheme autocmd registered')
    vim.health.info('  augroup: ' .. status.augroup)
    vim.health.info('  event: ' .. status.event)
    vim.health.info('  count: ' .. tostring(status.count))
  else
    vim.health.error('ColorScheme autocmd not registered or no autocmds found')
  end
end

function M.check()
  vim.health.start('project-color-nvim')

  check_plugin_loaded()
  check_config()
  check_projectconfig()
  check_theme()
  check_project_config()
  check_autocmds()
end

return M
