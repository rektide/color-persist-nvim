local M = {}
local config = require('project-color-nvim.config')
local theme = require('project-color-nvim.theme')
local env = require('project-color-nvim.env')

function M.setup()
  local augroup = config.get_augroup()
  
  local ok = pcall(vim.api.nvim_create_augroup, augroup, { clear = true })
  if not ok then
    return false, 'Failed to create augroup: ' .. augroup
  end

  vim.api.nvim_create_autocmd('ColorScheme', {
    group = augroup,
    callback = function()
      if not config.should_persist() then
        return
      end
      
      local current_theme = theme.get_current()
      if current_theme == '' then
        return
      end

      local env_file = env.get_filepath()
      local parse_ok, vars = pcall(env.parse, env_file)
      if not parse_ok then
        vim.notify('Failed to parse env file: ' .. vars, vim.log.levels.WARN)
        return
      end
      
      local nvim_color_key = config.get_nvim_color_key()
      local editor_color_key = config.get_editor_color_key()
      
      local vars_to_write = {}
      
      if vars[nvim_color_key] then
        vars_to_write[nvim_color_key] = current_theme
      else
        vars_to_write[editor_color_key] = current_theme
      end
      
      local write_ok, write_err = pcall(env.write, env_file, vars_to_write)
      if not write_ok then
        vim.notify('Failed to write env file: ' .. write_err, vim.log.levels.WARN)
      end
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
