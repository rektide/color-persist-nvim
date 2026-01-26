local M = {}

function M.get()
  local ok, pc = pcall(require, 'nvim-projectconfig')
  if not ok then return nil end
  return pc
end

return M
