local M = {}
local config = require('nvim-color-persist.config')
local theme = require('nvim-color-persist.theme')
local env = require('nvim-color-persist.env')
local autocmds = require('nvim-color-persist.autocmds')

local function load_from_env()
  local nvim_color_key = config.get_nvim_color_key()
  local editor_color_key = config.get_editor_color_key()
  
  local ok, system_vars = pcall(env.get_system_env)
  if not ok or not system_vars then
    return
  end
  
  local env_file = env.get_filepath()
  ok, file_vars = pcall(env.parse, env_file)
  if not ok or not file_vars then
    return
  end
  
  local theme_to_load = system_vars[nvim_color_key] 
                      or system_vars[editor_color_key]
                      or file_vars[nvim_color_key]
                      or file_vars[editor_color_key]
  
  if theme_to_load and theme_to_load ~= '' then
    local ok, err = pcall(theme.load, theme_to_load)
    if not ok then
      vim.notify('Failed to load theme: ' .. err, vim.log.levels.WARN)
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
