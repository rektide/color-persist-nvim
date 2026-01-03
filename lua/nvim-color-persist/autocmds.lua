local M = {}
local config = require('nvim-color-persist.config')
local theme = require('nvim-color-persist.theme')
local env = require('nvim-color-persist.env')

function M.setup()
  local augroup = config.get_augroup()
  vim.api.nvim_create_augroup(augroup, { clear = true })

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
end

return M
