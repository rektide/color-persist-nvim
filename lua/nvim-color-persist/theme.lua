local M = {}

function M.get_current()
  return vim.g.colors_name or ''
end

function M.load(theme_name)
  if theme_name and theme_name ~= '' then
    local ok = pcall(vim.cmd.colorscheme, theme_name)
    if not ok then
      vim.notify('Failed to load theme: ' .. theme_name, vim.log.levels.WARN)
    end
  end
end

return M
