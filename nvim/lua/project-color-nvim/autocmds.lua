local M = {}
local config = require('project-color-nvim.config')
local theme = require('project-color-nvim.theme')

local augroup_name = 'ProjectColorNvim'

function M.setup()
  local ok = pcall(vim.api.nvim_create_augroup, augroup_name, { clear = true })
  if not ok then
    return false, 'Failed to create augroup: ' .. augroup_name
  end

  vim.api.nvim_create_autocmd('ColorScheme', {
    group = augroup_name,
    callback = function()
      if not config.should_persist() then
        return
      end

      local projectconfig_ok, projectconfig = pcall(require, 'nvim-projectconfig')
      if not projectconfig_ok or not projectconfig then
        vim.notify('nvim-projectconfig not available', vim.log.levels.WARN)
        return
      end

      local current_theme = theme.get_current()
      if current_theme == '' then
        return
      end

      local load_ok, data = pcall(projectconfig.load_json)
      if not load_ok or not data then
        data = {}
      end

      if data['color-persist'] == current_theme then
        return
      end

      data['color-persist'] = current_theme

      local save_ok, save_err = pcall(projectconfig.save_json, data)
      if not save_ok then
        vim.notify('Failed to save project config: ' .. save_err, vim.log.levels.WARN)
      end
    end,
  })

  return true
end

function M.is_registered()
  local ok, _ = pcall(vim.api.nvim_get_autocmds, {
    group = augroup_name,
    event = 'ColorScheme'
  })
  return ok
end

function M.get_status()
  local ok, autocmds = pcall(vim.api.nvim_get_autocmds, {
    group = augroup_name,
    event = 'ColorScheme'
  })

  return {
    registered = ok,
    augroup = augroup_name,
    event = 'ColorScheme',
    count = ok and #autocmds or 0,
  }
end

function M.check_augroup_exists()
  local ok, augroups = pcall(vim.api.nvim_get_augroups_by_name, augroup_name)
  return ok and augroups ~= nil
end

return M
