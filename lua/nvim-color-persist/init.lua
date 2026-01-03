local M = {}
local config = require('nvim-color-persist.config')
local theme = require('nvim-color-persist.theme')
local env = require('nvim-color-persist.env')
local autocmds = require('nvim-color-persist.autocmds')

local function load_from_env()
  local nvim_color_key = config.get_nvim_color_key()
  local editor_color_key = config.get_editor_color_key()
  
  local system_vars = env.get_system_env()
  local env_file = env.get_filepath()
  local file_vars = env.parse(env_file)
  
  if system_vars[nvim_color_key] and system_vars[nvim_color_key] ~= '' then
    theme.load(system_vars[nvim_color_key])
  elseif system_vars[editor_color_key] and system_vars[editor_color_key] ~= '' then
    theme.load(system_vars[editor_color_key])
  elseif file_vars[nvim_color_key] and file_vars[nvim_color_key] ~= '' then
    theme.load(file_vars[nvim_color_key])
  elseif file_vars[editor_color_key] and file_vars[editor_color_key] ~= '' then
    theme.load(file_vars[editor_color_key])
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
