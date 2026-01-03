local M = {}
local config = require('project-color-nvim.config')
local theme = require('project-color-nvim.theme')
local env = require('project-color-nvim.env')
local autocmds = require('project-color-nvim.autocmds')

local function check_plugin_loaded()
  local loaded = config.check_loaded()
  if loaded then
    vim.health.ok('project-color-nvim plugin loaded')
  else
    vim.health.error('project-color-nvim plugin not loaded')
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
  
  local env_disabled = vim.env.NVIM_COLOR_PERSIST
  if env_disabled == '0' or env_disabled == 'false' then
    vim.health.warn('Plugin disabled by NVIM_COLOR_PERSIST environment variable')
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

local function check_system_env()
  local system_vars = env.get_system_env()
  local nvim_color_key = config.get_nvim_color_key()
  local editor_color_key = config.get_editor_color_key()
  
  local has_system_vars = false
  
  if system_vars[nvim_color_key] and system_vars[nvim_color_key] ~= '' then
    vim.health.ok('System env ' .. nvim_color_key .. ' set to: ' .. system_vars[nvim_color_key])
    has_system_vars = true
  end
  
  if system_vars[editor_color_key] and system_vars[editor_color_key] ~= '' then
    vim.health.ok('System env ' .. editor_color_key .. ' set to: ' .. system_vars[editor_color_key])
    has_system_vars = true
  end
  
  if not has_system_vars then
    vim.health.info('No system env vars set for theme')
  end
end

local function check_env_file()
  local stat = env.get_file_status()
  
  if not stat then
    vim.health.info('No env file found: ' .. env.get_filepath())
    return
  end
  
  vim.health.ok('Env file exists: ' .. stat.path)
  
  local vars = env.parse(stat.path)
  local validation = env.validate_vars(vars)
  local nvim_color_key = config.get_nvim_color_key()
  local editor_color_key = config.get_editor_color_key()
  
  if validation.has_nvim_color then
    vim.health.ok(nvim_color_key .. ' set to: ' .. vars[nvim_color_key])
  else
    vim.health.info(nvim_color_key .. ' not set in env file')
  end
  
  if validation.has_editor_value then
    vim.health.ok(editor_color_key .. ' set to: ' .. vars[editor_color_key])
  else
    vim.health.info(editor_color_key .. ' not set in env file')
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
  vim.health.start('project-color-nvim')
  
  check_plugin_loaded()
  check_config()
  check_system_env()
  check_theme()
  check_env_file()
  check_autocmds()
end

return M
