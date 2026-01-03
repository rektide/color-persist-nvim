local M = {}

function M.get_current()
  return vim.g.colors_name or ''
end

function M.load(theme_name)
  if type(theme_name) ~= 'string' or theme_name == '' then
    return
  end
  
  local ok = pcall(vim.cmd.colorscheme, theme_name)
  if not ok then
    vim.notify('Failed to load theme: ' .. theme_name, vim.log.levels.WARN)
  end
end

function M.check_status()
  local theme_name = M.get_current()
  return {
    loaded = theme_name ~= '',
    theme_name = theme_name,
  }
end

return M
