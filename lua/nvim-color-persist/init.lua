local M = {}
local config = require('nvim-color-persist.config')
local theme = require('nvim-color-persist.theme')
local env = require('nvim-color-persist.env')
local autocmds = require('nvim-color-persist.autocmds')

local function load_from_env()
  local env_file = env.get_filepath()
  local vars = env.parse(env_file)
  local nvim_color_key = config.get_nvim_color_key()
  local editor_color_key = config.get_editor_color_key()
  
  if vars[nvim_color_key] and vars[nvim_color_key] ~= '' then
    theme.load(vars[nvim_color_key])
  elseif vars[editor_color_key] and vars[editor_color_key] ~= '' then
    theme.load(vars[editor_color_key])
  end
end

function M.setup(opts)
  local ok, err = pcall(config.setup, opts)
  if not ok then
    vim.notify('nvim-color-persist configuration error: ' .. err, vim.log.levels.ERROR)
    return false
  end
  
  load_from_env()
  
  local setup_ok, setup_err = pcall(autocmds.setup)
  if not setup_ok then
    vim.notify('nvim-color-persist autocmd setup failed: ' .. setup_err, vim.log.levels.ERROR)
    return false
  end
  
  return true
end

return M
