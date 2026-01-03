local M = {}
local config = require('nvim-color-persist.config')
local theme = require('nvim-color-persist.theme')
local env = require('nvim-color-persist.env')
local autocmds = require('nvim-color-persist.autocmds')

local function load_from_env()
  local nvim_color_key = config.get_nvim_color_key()
  local editor_color_key = config.get_editor_color_key()
  
  local system_vars_ok, system_vars = pcall(env.get_system_env)
  if not system_vars_ok then
    vim.notify('Failed to get system env vars: ' .. system_vars, vim.log.levels.WARN)
    return
  end
  
  local env_file = env.get_filepath()
  local file_vars_ok, file_vars = pcall(env.parse, env_file)
  if not file_vars_ok then
    vim.notify('Failed to read env file: ' .. file_vars, vim.log.levels.WARN)
  end
  
  local loaded = false
  
  if system_vars[nvim_color_key] and system_vars[nvim_color_key] ~= '' then
    local ok, err = pcall(theme.load, system_vars[nvim_color_key])
    if not ok then
      vim.notify('Failed to load system NVIM_COLOR theme: ' .. err, vim.log.levels.WARN)
    else
      loaded = true
    end
  elseif system_vars[editor_color_key] and system_vars[editor_color_key] ~= '' then
    local ok, err = pcall(theme.load, system_vars[editor_color_key])
    if not ok then
      vim.notify('Failed to load system EDITOR_COLOR theme: ' .. err, vim.log.levels.WARN)
    else
      loaded = true
    end
  elseif file_vars_ok and file_vars[nvim_color_key] and file_vars[nvim_color_key] ~= '' then
    local ok, err = pcall(theme.load, file_vars[nvim_color_key])
    if not ok then
      vim.notify('Failed to load file NVIM_COLOR theme: ' .. err, vim.log.levels.WARN)
    else
      loaded = true
    end
  elseif file_vars_ok and file_vars[editor_color_key] and file_vars[editor_color_key] ~= '' then
    local ok, err = pcall(theme.load, file_vars[editor_color_key])
    if not ok then
      vim.notify('Failed to load file EDITOR_COLOR theme: ' .. err, vim.log.levels.WARN)
    else
      loaded = true
    end
  end
end

function M.setup(opts)
  local ok, err = pcall(config.setup, opts)
  if not ok then
    vim.notify('nvim-color-persist configuration error: ' .. err, vim.log.levels.ERROR)
    return false
  end
  
  if not config.is_enabled() then
    return true
  end
  
  if config.should_autoload() then
    load_from_env()
  end
  
  local setup_ok, setup_err = pcall(autocmds.setup)
  if not setup_ok then
    vim.notify('nvim-color-persist autocmd setup failed: ' .. setup_err, vim.log.levels.ERROR)
    return false
  end
  
  return true
end

return M
