local M = {}
local config = require('nvim-color-persist.config')
local theme = require('nvim-color-persist.theme')
local env = require('nvim-color-persist.env')
local autocmds = require('nvim-color-persist.autocmds')

local function check_plugin_loaded()
  local loaded = config.check_loaded()
  if loaded then
    vim.health.ok('nvim-color-persist plugin loaded')
  else
    vim.health.error('nvim-color-persist plugin not loaded')
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
    vim.health.info('  env_file: ' .. config.get_env_file())
    vim.health.info('  augroup: ' .. config.get_augroup())
    vim.health.info('  nvim_color_key: ' .. config.get_nvim_color_key())
    vim.health.info('  editor_color_key: ' .. config.get_editor_color_key())
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

local function check_env_file()
  local file_status = env.get_file_status()
  
  if not file_status.exists then
    vim.health.info('No env file found: ' .. file_status.path)
    return
  end
  
  if file_status.type ~= 'file' then
    vim.health.error('Env file exists but is not a regular file: ' .. file_status.path)
    return
  end
  
  vim.health.ok('Env file exists: ' .. file_status.path)
  
  if not env.check_readability() then
    vim.health.warn('Could not open env file for reading')
    return
  end
  
  local vars = env.parse(file_status.path)
  local validation = env.validate_vars(vars)
  
  for _, item in ipairs(validation.set) do
    vim.health.ok(item.key .. ' set to: ' .. item.value)
  end
  
  for _, key in ipairs(validation.empty) do
    vim.health.warn(key .. ' is empty')
  end
  
  for _, key in ipairs(validation.missing) do
    vim.health.info(key .. ' not set in env file')
  end
end

local function check_autocmds()
  local status = autocmds.get_status()
  
  if status.registered then
    vim.health.ok('ColorScheme autocmd registered')
    vim.health.info('  augroup: ' .. status.augroup)
    vim.health.info('  event: ' .. status.event)
    vim.health.info('  count: ' .. tostring(status.count))
  else
    vim.health.error('ColorScheme autocmd not registered')
  end
end

function M.check()
  vim.health.start('nvim-color-persist')
  
  check_plugin_loaded()
  check_config()
  check_theme()
  check_env_file()
  check_autocmds()
end

return M
