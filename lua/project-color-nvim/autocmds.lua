local M = {}
local config = require('project-color-nvim.config')
local theme = require('project-color-nvim.theme')
local projectconfig = require('project-color-nvim.projectconfig')

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

      local current_theme = theme.get_current()
      if current_theme == '' then
        return
      end

      local pc = projectconfig.get()
      if not pc then
        if config.should_notify() then
          vim.notify('nvim-projectconfig not available', vim.log.levels.WARN)
        end
        return
      end

      local data, load_err = pcall(pc.load_json)
      if not data or type(data) ~= 'table' then
        data = {}
      end

      local key = config.get_key()
      if data[key] == current_theme then
        return
      end

      data[key] = current_theme

      local save_ok, save_err = pcall(pc.save_json, data)
      if not save_ok then
        if config.should_notify() then
          vim.notify('Failed to save project config: ' .. (save_err or 'unknown error'), vim.log.levels.WARN)
        end
      end
    end,
  })

  return true
end

function M.setup_dirchanged_autocmd(load_from_project_config)
  vim.api.nvim_create_autocmd('DirChanged', {
    group = augroup_name,
    callback = function()
      if config.should_autoload() then
        load_from_project_config()
      end
    end,
  })
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
  local ok, autocmds = pcall(vim.api.nvim_get_autocmds, {
    group = augroup_name,
  })
  return ok and #autocmds > 0
end

return M
