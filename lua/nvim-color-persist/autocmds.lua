local M = {}
local config = require('nvim-color-persist.config')
local theme = require('nvim-color-persist.theme')
local env = require('nvim-color-persist.env')

function M.setup()
  local augroup = config.get_augroup()
  
  local ok = pcall(vim.api.nvim_create_augroup, augroup, { clear = true })
  if not ok then
    return false, 'Failed to create augroup: ' .. augroup
  end

  vim.api.nvim_create_autocmd('ColorScheme', {
    group = augroup,
    callback = function()
      local current_theme = theme.get_current()
      if current_theme == '' then
        return
      end

      local env_file = env.get_filepath()
      local vars = env.parse(env_file)
      local nvim_color_key = config.get_nvim_color_key()
      local editor_color_key = config.get_editor_color_key()
      
      vars[nvim_color_key] = current_theme
      
      if not vars[editor_color_key] or vars[editor_color_key] == current_theme then
        vars[editor_color_key] = current_theme
      end
      
      env.write(env_file, vars)
    end,
  })
  
  return true
end

function M.is_registered()
  local augroup = config.get_augroup()
  local ok, _ = pcall(vim.api.nvim_get_autocmds, {
    group = augroup,
    event = 'ColorScheme'
  })
  return ok
end

function M.get_status()
  local augroup = config.get_augroup()
  local ok, autocmds = pcall(vim.api.nvim_get_autocmds, {
    group = augroup,
    event = 'ColorScheme'
  })
  
  return {
    registered = ok,
    augroup = augroup,
    event = 'ColorScheme',
    count = ok and #autocmds or 0,
  }
end

function M.check_augroup_exists()
  local augroup = config.get_augroup()
  local ok, augroups = pcall(vim.api.nvim_get_augroups_by_name, augroup)
  return ok and augroups ~= nil
end

return M
