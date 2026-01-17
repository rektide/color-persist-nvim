local M = {}
local config = require('project-color-nvim.config')
local theme = require('project-color-nvim.theme')
local autocmds = require('project-color-nvim.autocmds')
local projectconfig = require('project-color-nvim.projectconfig')

M._state = {
  setup_called = false,
  setup_succeeded = false,
  theme_loaded = nil,
}

local function load_from_project_config()
  local data, err = projectconfig.read()
  if err then
    vim.notify(err, vim.log.levels.WARN)
    return
  end

  local theme_to_load = data['color-persist']
  if theme_to_load and theme_to_load ~= '' then
    local ok, load_err = theme.load(theme_to_load)
    if not ok then
      vim.notify('Failed to load theme: ' .. (load_err or 'unknown error'), vim.log.levels.WARN)
    end
  end
end

function M.setup(opts)
  M._state.setup_called = true

  local ok, err = pcall(config.setup, opts)
  if not ok then
    vim.notify('project-color-nvim configuration error: ' .. err, vim.log.levels.ERROR)
    M._state.setup_succeeded = false
    return false
  end

  if not config.is_enabled() then
    M._state.setup_succeeded = true
    return true
  end

  if config.should_autoload() then
    load_from_project_config()
  end

  local setup_ok, setup_err = autocmds.setup()
  if not setup_ok then
    vim.notify('project-color-nvim autocmd setup failed: ' .. (setup_err or 'unknown error'), vim.log.levels.ERROR)
    M._state.setup_succeeded = false
    return false
  end

  M._state.setup_succeeded = true
  return true
end

return M
