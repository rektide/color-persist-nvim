local M = {}
local config = require('project-color-nvim.config')
local theme = require('project-color-nvim.theme')
local autocmds = require('project-color-nvim.autocmds')

local function load_from_project_config()
  local ok, projectconfig = pcall(require, 'nvim-projectconfig')
  if not ok or not projectconfig then
    vim.notify('nvim-projectconfig not available', vim.log.levels.WARN)
    return
  end

  local config_ok, data = pcall(projectconfig.load_json)
  if not config_ok or not data then
    return
  end

  local theme_to_load = data['color-persist']
  if theme_to_load and theme_to_load ~= '' then
    local ok, err = theme.load(theme_to_load)
    if not ok then
      vim.notify('Failed to load theme: ' .. (err or 'unknown error'), vim.log.levels.WARN)
    end
  end
end

function M.setup(opts)
  local ok, err = pcall(config.setup, opts)
  if not ok then
    vim.notify('project-color-nvim configuration error: ' .. err, vim.log.levels.ERROR)
    return false
  end
  
  if not config.is_enabled() then
    return true
  end
  
  if config.should_autoload() then
    load_from_project_config()
  end
  
  local setup_ok, setup_err = autocmds.setup()
  if not setup_ok then
    vim.notify('project-color-nvim autocmd setup failed: ' .. (setup_err or 'unknown error'), vim.log.levels.ERROR)
    return false
  end
  
  return true
end

return M
