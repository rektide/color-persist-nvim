if vim.fn.has("nvim-0.8") == 0 then
  vim.notify("project-color-nvim requires Neovim 0.8+", vim.log.levels.ERROR)
  return
end

local M = {}

vim.api.nvim_create_autocmd('VimEnter', {
  group = vim.api.nvim_create_augroup('ProjectColorNvimAutosetup', { clear = true }),
  callback = function()
    if vim.g.project_color_nvim_autosetup ~= false and vim.g.loaded_project_color_nvim ~= 1 then
      vim.g.loaded_project_color_nvim = 1
      require('project-color-nvim').setup()
    end
  end,
})

return M
