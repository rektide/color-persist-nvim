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
  config.setup(opts)
  load_from_env()
  autocmds.setup()
end

return M
